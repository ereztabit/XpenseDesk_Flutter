import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/expense_provider.dart';

class ReceiptAnalyzerDialog extends ConsumerStatefulWidget {
  const ReceiptAnalyzerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ReceiptAnalyzerDialog(),
    );
  }

  @override
  ConsumerState<ReceiptAnalyzerDialog> createState() =>
      _ReceiptAnalyzerDialogState();
}

class _ReceiptAnalyzerDialogState extends ConsumerState<ReceiptAnalyzerDialog> {
  static int _pdfViewTypeCounter = 0;

  Uint8List? _selectedBytes;
  String? _selectedFilename;
  int? _fileSizeKb;
  int? _imageWidth;
  int? _imageHeight;
  bool _isPdf = false;
  String? _pdfBlobUrl;
  String? _pdfViewType;
  bool _isLoading = false;
  String? _result;
  bool _isError = false;

  @override
  void dispose() {
    _revokePdfBlob();
    super.dispose();
  }

  void _revokePdfBlob() {
    if (_pdfBlobUrl != null) {
      web.URL.revokeObjectURL(_pdfBlobUrl!);
      _pdfBlobUrl = null;
    }
  }

  Future<void> _pickFile() async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.jpg,.jpeg,.png,.pdf';
    input.click();

    await input.onChange.first;

    final files = input.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0)!;
    final arrayBuffer = await file.arrayBuffer().toDart;
    final bytes = arrayBuffer.toDart.asUint8List();
    final isPdf = file.name.toLowerCase().endsWith('.pdf');

    _revokePdfBlob();

    String? pdfBlobUrl;
    String? pdfViewType;

    if (isPdf) {
      final blob = web.Blob(
        [bytes.buffer.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );
      pdfBlobUrl = web.URL.createObjectURL(blob);
      pdfViewType = 'pdf-preview-${++_pdfViewTypeCounter}';
      final capturedUrl = pdfBlobUrl;
      ui_web.platformViewRegistry.registerViewFactory(
        pdfViewType,
        (int id) => web.HTMLEmbedElement()
          ..src = capturedUrl
          ..type = 'application/pdf'
          ..setAttribute('style', 'width:100%;height:100%;border:none;'),
      );
    }

    if (!mounted) return;
    setState(() {
      _selectedBytes = bytes;
      _selectedFilename = file.name;
      _fileSizeKb = (bytes.length / 1024).ceil();
      _isPdf = isPdf;
      _pdfBlobUrl = pdfBlobUrl;
      _pdfViewType = pdfViewType;
      _imageWidth = null;
      _imageHeight = null;
      _result = null;
      _isError = false;
    });

    if (!isPdf) {
      ui.decodeImageFromList(bytes, (img) {
        if (mounted) {
          setState(() {
            _imageWidth = img.width;
            _imageHeight = img.height;
          });
        }
      });
    }
  }

  Future<void> _analyze() async {
    final bytes = _selectedBytes;
    final filename = _selectedFilename;
    if (bytes == null || filename == null) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _isError = false;
    });

    try {
      final expenseService = ref.read(expenseServiceProvider);
      final json = await expenseService.analyzeReceipt(bytes, filename);
      if (!mounted) return;
      setState(() {
        _result = json;
        _isError = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = e.toString();
        _isError = true;
        _isLoading = false;
      });
    }
  }

  void _showFullScreenImage(BuildContext context) {
    final bytes = _selectedBytes;
    if (bytes == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(230),
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(AppLocalizations l10n) {
    final bytes = _selectedBytes;
    if (bytes == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppTheme.muted,
            alignment: Alignment.center,
            child: _isPdf
                ? (_pdfViewType != null
                    ? HtmlElementView(viewType: _pdfViewType!)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              size: 64, color: AppTheme.destructive),
                          const SizedBox(height: 8),
                          Text(l10n.receiptAnalyzerPdfDocument,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ))
                : Tooltip(
                    message: l10n.receiptAnalyzerExpandImage,
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.zoomIn,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${l10n.receiptAnalyzerSize}: $_fileSizeKb KB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_imageWidth != null && _imageHeight != null) ...[
              const SizedBox(width: 16),
              Text(
                '${l10n.receiptAnalyzerDimensions}: $_imageWidth × $_imageHeight px',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.receiptAnalyzerTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(l10n.receiptAnalyzerPickImage),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFilename ?? l10n.receiptAnalyzerNoFileSelected,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              _buildPreview(l10n),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (_selectedBytes != null && !_isLoading)
                    ? _analyze
                    : null,
                child: Text(
                  _isLoading
                      ? l10n.receiptAnalyzerAnalyzing
                      : l10n.receiptAnalyzerAnalyze,
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                Text(
                  _isError
                      ? l10n.receiptAnalyzerError
                      : l10n.receiptAnalyzerResult,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isError
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    border: Border.all(
                      color: _isError
                          ? Theme.of(context).colorScheme.error
                          : AppTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _result!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
