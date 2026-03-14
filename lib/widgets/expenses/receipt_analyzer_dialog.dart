import 'dart:typed_data';
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
  Uint8List? _selectedBytes;
  String? _selectedFilename;
  bool _isLoading = false;
  String? _result;
  bool _isError = false;

  Future<void> _pickFile() async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.jpg,.jpeg,.png';
    input.click();

    await input.onChange.first;

    final files = input.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0)!;
    final arrayBuffer = await file.arrayBuffer().toDart;
    final bytes = arrayBuffer.toDart.asUint8List();

    if (!mounted) return;
    setState(() {
      _selectedBytes = bytes;
      _selectedFilename = file.name;
      _result = null;
      _isError = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
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
                  constraints: const BoxConstraints(maxHeight: 300),
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
