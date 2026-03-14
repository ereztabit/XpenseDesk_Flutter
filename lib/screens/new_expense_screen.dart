import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'screen_imports.dart';
import '../utils/responsive_utils.dart';
import '../widgets/expenses/expense_step_indicator.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen>
    with FormBehaviorMixin {
  static int _pdfViewTypeCounter = 0;

  int _currentStep = 0;
  Uint8List? _fileBytes;
  String? _filename;
  int? _fileSizeKb;
  bool _isPdf = false;
  String? _pdfBlobUrl;
  String? _pdfViewType;
  int? _imageWidth;
  int? _imageHeight;
  bool _isHovering = false;

  @override
  void dispose() {
    _revokePdfBlob();
    super.dispose();
  }

  @override
  bool get hasUnsavedChanges => false; // Step 5 will set this when form has data

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
      pdfViewType = 'new-expense-pdf-${++_pdfViewTypeCounter}';
      final capturedUrl = pdfBlobUrl;
      ui_web.platformViewRegistry.registerViewFactory(
        pdfViewType,
        (int id) => web.HTMLIFrameElement()
          ..src = '$capturedUrl#toolbar=0&navpanes=0&scrollbar=0&view=FitH'
          ..setAttribute('style', 'width:100%;height:100%;border:none;'),
      );
    }

    if (!mounted) return;
    setState(() {
      _fileBytes = bytes;
      _filename = file.name;
      _fileSizeKb = (bytes.length / 1024).ceil();
      _isPdf = isPdf;
      _pdfBlobUrl = pdfBlobUrl;
      _pdfViewType = pdfViewType;
      _imageWidth = null;
      _imageHeight = null;
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

  void _downloadFile() {
    final bytes = _fileBytes;
    final filename = _filename;
    if (bytes == null || filename == null) return;

    final mimeType = _isPdf
        ? 'application/pdf'
        : filename.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';

    final blob = web.Blob(
      [bytes.buffer.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    a.click();
    web.URL.revokeObjectURL(url);
  }

  // Stub: wired up in Step 3 to trigger AI scan
  Future<void> _analyze() async {}

  void _showFullScreenImage(BuildContext context) {
    final bytes = _fileBytes;
    if (bytes == null || _isPdf) return;
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
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone(AppLocalizations l10n, double height) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _pickFile,
        child: SizedBox(
          height: height,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: _isHovering ? AppTheme.primary : AppTheme.border,
              strokeWidth: 2,
              borderRadius: 8,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isHovering
                    ? AppTheme.muted.withAlpha(128)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.newExpenseUploadTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.newExpenseUploadSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.newExpenseUploadFormats,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewOverlayButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppTheme.foreground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AppLocalizations l10n, double previewHeight) {
    final bytes = _fileBytes!;
    final isDesktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PDF: plain container, no Stack — HtmlElementView can't be in a Stack
        if (_isPdf)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: previewHeight,
              color: AppTheme.muted,
              alignment: Alignment.center,
              child: _pdfViewType != null
                  ? HtmlElementView(viewType: _pdfViewType!)
                  : const SizedBox.shrink(),
            ),
          )
        // Image: Stack so overlay buttons render correctly
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: previewHeight,
                  color: AppTheme.muted,
                  alignment: Alignment.center,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    height: previewHeight,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPreviewOverlayButton(
                          icon: Icons.open_in_full,
                          tooltip: l10n.newExpenseExpandImage,
                          onTap: () => _showFullScreenImage(context),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 4),
                          _buildPreviewOverlayButton(
                            icon: Icons.download_outlined,
                            tooltip: l10n.newExpenseDownloadReceipt,
                            onTap: _downloadFile,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _fileSizeKb != null
                    ? '$_filename  ·  $_fileSizeKb KB'
                    : _filename ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_imageWidth != null && _imageHeight != null) ...[
              Text(
                '$_imageWidth × $_imageHeight px',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
            ],
            if (isDesktop && _isPdf)
              TextButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(l10n.newExpenseDownloadReceipt),
              ),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: Text(l10n.newExpenseReplaceFile),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contentHeight =
        (MediaQuery.of(context).size.height * 0.5).clamp(320.0, 600.0);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            handleBackNavigation('/user/dashboard'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(l10n.backToDashboard),
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.newExpense,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExpenseStepIndicator(
                                  currentStep: _currentStep),
                              const SizedBox(height: 32),
                              if (_fileBytes == null)
                                _buildUploadZone(l10n, contentHeight)
                              else ...[
                                _buildPreview(context, l10n, contentHeight),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _analyze,
                                    child: Text(l10n.newExpenseAnalyzeButton),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rRect);

    const dashLength = 8.0;
    const gapLength = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
