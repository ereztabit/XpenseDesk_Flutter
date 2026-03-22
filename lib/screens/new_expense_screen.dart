import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'screen_imports.dart';
import '../utils/responsive_utils.dart';
import '../utils/format_utils.dart';
import '../utils/expense_amount_input_formatter.dart';
import '../widgets/expenses/expense_step_indicator.dart';
import '../widgets/expenses/expense_create_image_panel.dart';
import '../providers/expense_provider.dart';
import '../services/expense_service.dart';
import '../models/receipt_analysis_result.dart';
import '../models/expense_category.dart';
import '../models/expense_currency.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen>
    with FormBehaviorMixin, TickerProviderStateMixin {
  static int _pdfViewTypeCounter = 0;

  // Step 1 — upload/preview state
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
  bool _isAnalyzing = false;
  ReceiptAnalysisResult? _analysisResult;
  bool _aiFailed = false;

  // Step 2 — form state
  int? _selectedCategoryId;
  String? _selectedCurrencyCode;
  DateTime? _selectedDate;
  bool _isModifying = false;
  bool _isSubmitting = false;
  String? _submitError;
  bool _isAiData = false;
  bool _hasAttemptedSubmit = false;
  String? _aiImageUrl;

  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final AnimationController _shakeCategoryController;
  late final Animation<double> _shakeCategoryAnimation;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late final TextEditingController _receiptRefController;
  late final FocusNode _dateFocusNode;
  late final TextEditingController _categoryController;
  String? _dateInputError;
  final _categoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shakeCategoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeCategoryAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeCategoryController, curve: Curves.easeInOut),
    );
    _categoryController = TextEditingController();
    _categoryController.addListener(_onCategoryTextChanged);
    _amountController = TextEditingController();
    _merchantController = TextEditingController();
    _noteController = TextEditingController();
    _dateController = TextEditingController();
    _receiptRefController = TextEditingController();
    _dateFocusNode = FocusNode()
      ..addListener(() {
        if (!_dateFocusNode.hasFocus) _validateDateInput();
      });
    _amountController.addListener(_onFormChanged);
    _merchantController.addListener(_onFormChanged);
    _dateController.addListener(_onFormChanged);
    _receiptRefController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _shakeCategoryController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _dateFocusNode.dispose();
    _receiptRefController.dispose();
    _revokePdfBlob();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  void _onCategoryTextChanged() {
    if (_selectedCategoryId == null) return;
    final text = _categoryController.text;
    if (text.isEmpty) {
      setState(() => _selectedCategoryId = null);
      return;
    }
    final locale = Localizations.localeOf(context);
    final matchesAny = ExpenseCategory.orderedValues
        .any((c) => c.labelForLocale(locale) == text);
    if (!matchesAny) {
      setState(() => _selectedCategoryId = null);
    }
  }

  /// Updates [_categoryController] text to match [categoryId]'s label.
  /// Call AFTER the setState that sets [_selectedCategoryId].
  void _syncCategoryController(int? categoryId) {
    if (categoryId == null) {
      _categoryController.text = '';
      return;
    }
    final locale = Localizations.localeOf(context);
    final cat = ExpenseCategory.orderedValues
        .where((c) => c.id == categoryId)
        .firstOrNull;
    _categoryController.text = cat?.labelForLocale(locale) ?? '';
  }

  @override
  bool get hasUnsavedChanges => false;

  // True when the mandatory typed fields are filled — enables the button so
  // _submit() can run and scroll to any missing field (e.g. category).
  bool get _canAttemptSubmit =>
      _amountController.text.trim().isNotEmpty &&
      _merchantController.text.trim().isNotEmpty &&
      _dateController.text.trim().isNotEmpty &&
      _dateInputError == null;

  // True when every required field is valid — drives the green "ready" style.
  bool get _canSubmit => _canAttemptSubmit && _selectedCategoryId != null;

  // ── File handling ──────────────────────────────────────────────────────────

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

  void _resetToUpload() {
    _revokePdfBlob();
    _amountController.clear();
    _merchantController.clear();
    _noteController.clear();
    _dateController.clear();
    _receiptRefController.clear();
    setState(() {
      _fileBytes = null;
      _filename = null;
      _fileSizeKb = null;
      _isPdf = false;
      _pdfViewType = null;
      _imageWidth = null;
      _imageHeight = null;
      _currentStep = 0;
      _analysisResult = null;
      _aiFailed = false;
      _selectedCategoryId = null;
      _selectedCurrencyCode = null;
      _selectedDate = null;
      _isModifying = false;
      _isSubmitting = false;
      _submitError = null;
      _isAiData = false;
      _hasAttemptedSubmit = false;
      _aiImageUrl = null;
    });
    _syncCategoryController(null);
  }

  void _undoAiModify() {
    final result = _analysisResult;
    if (result == null) {
      setState(() => _isModifying = false);
      return;
    }
    setState(() {
      _isModifying = false;
      _selectedCategoryId = result.categoryId;
      _selectedCurrencyCode = result.currencyCode ?? 'ILS';
      _selectedDate = result.expenseDate != null
          ? DateTime.tryParse(result.expenseDate!)
          : null;
      _dateController.text = result.expenseDate != null
          ? _isoToDisplayDate(
              result.expenseDate!, ref.read(companyLocaleProvider))
          : '';
      _amountController.text =
          result.amount != null ? _formatAmount(result.amount!) : '';
      _merchantController.text = result.merchantName ?? '';
      _receiptRefController.text = result.receiptNumber ?? '';
    });
    _syncCategoryController(result.categoryId);
  }

  String _formatAmount(double amount) {
    final fmt = NumberFormat('#,##0.##', 'en');
    return fmt.format(amount);
  }

  // ── AI analysis ────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    final bytes = _fileBytes;
    final filename = _filename;
    if (bytes == null || filename == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _aiFailed = false;
    });
    _scanController.repeat();
    _pulseController.repeat();

    try {
      final expenseService = ref.read(expenseServiceProvider);
      final result = await expenseService.analyzeReceiptParsed(bytes, filename);
      if (!mounted) return;
      _scanController.stop();
      _pulseController.stop();

      if (result.aiFailed) {
        setState(() {
          _aiFailed = true;
          _isAnalyzing = false;
          _currentStep = 1;
          _selectedCurrencyCode = 'ILS';
          _aiImageUrl = result.imageUrl;
        });
        return;
      }

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        _currentStep = 1;
        _selectedCategoryId = result.categoryId;
        _selectedCurrencyCode = result.currencyCode ?? 'ILS';
        _selectedDate = result.expenseDate != null
            ? DateTime.tryParse(result.expenseDate!)
            : null;
        if (result.expenseDate != null) {
          _dateController.text = _isoToDisplayDate(
              result.expenseDate!, ref.read(companyLocaleProvider));
        }
        if (result.amount != null) {
          _amountController.text = _formatAmount(result.amount!);
        }
        if (result.merchantName != null) {
          _merchantController.text = result.merchantName!;
        }
        if (result.receiptNumber != null) {
          _receiptRefController.text = result.receiptNumber!;
        }
        _aiImageUrl = result.imageUrl;
        _isAiData = true;
      });
      _syncCategoryController(result.categoryId);
    } catch (_) {
      if (!mounted) return;
      _scanController.stop();
      _pulseController.stop();
      setState(() {
        _aiFailed = true;
        _isAnalyzing = false;
        _currentStep = 1;
        _selectedCurrencyCode = 'ILS';
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _hasAttemptedSubmit = true);

    if (_selectedCategoryId == null) {
      _shakeCategoryController.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _categoryKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }

    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    final categoryId = _selectedCategoryId;
    final merchant = _merchantController.text.trim();
    final currency = _selectedCurrencyCode;
    final date = _selectedDate ?? DateTime.now();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final receiptRef = _receiptRefController.text.trim().isEmpty
        ? null
        : _receiptRefController.text.trim();

    if (amount == null || categoryId == null || merchant.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final expenseService = ref.read(expenseServiceProvider);
      await expenseService.createExpense(
        expenseDate: date,
        categoryId: categoryId,
        amount: amount,
        currencyCode: currency,
        merchantName: merchant,
        note: note,
        receiptRef: receiptRef,
        imageUrl: _aiImageUrl,
        isAiData: _isAiData,
      );
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      Navigator.of(context).pushReplacementNamed('/user/dashboard');
    } on ExpenseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.toString();
      });
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

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

  // ── Step 1 widgets ─────────────────────────────────────────────────────────

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

  Widget _buildScanningOverlay(double height) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanController, _pulseController]),
      builder: (context, _) {
        final scanPos = _scanController.value;
        final pulseScale =
            0.85 + 0.3 * (0.5 + 0.5 * sin(_pulseController.value * 2 * pi));

        double dotOffset(int index) {
          final t = ((_pulseController.value + index * 0.167) % 1.0);
          return -8.0 * sin(t * pi).clamp(0.0, 1.0);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              children: [
                if (!_isPdf)
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.muted,
                      alignment: Alignment.center,
                      child: Image.memory(
                        _fileBytes!,
                        fit: BoxFit.contain,
                        height: height,
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(color: AppTheme.muted),
                  ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: AppTheme.background.withAlpha(153),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: scanPos * (height - 4),
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                ..._cornerBrackets(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40 + 24 * _pulseController.value,
                            height: 40 + 24 * _pulseController.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(
                                  (77 * (1 - _pulseController.value)).round(),
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: pulseScale,
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.newExpenseAnalyzing,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Transform.translate(
                              offset: Offset(0, dotOffset(i)),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _cornerBrackets() {
    const double size = 32;
    const double inset = 16;
    const double thickness = 2;
    final color = AppTheme.primary;

    Widget bracket({required bool top, required bool start}) {
      return PositionedDirectional(
        top: top ? inset : null,
        bottom: top ? null : inset,
        start: start ? inset : null,
        end: start ? null : inset,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerBracketPainter(
              top: top,
              start: start,
              color: color,
              thickness: thickness,
            ),
          ),
        ),
      );
    }

    return [
      bracket(top: true, start: true),
      bracket(top: true, start: false),
      bracket(top: false, start: true),
      bracket(top: false, start: false),
    ];
  }

  Widget _buildPreview(
      BuildContext context, AppLocalizations l10n, double previewHeight) {
    final bytes = _fileBytes!;
    final isDesktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAnalyzing)
          _buildScanningOverlay(previewHeight)
        else if (_isPdf)
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
        if (!_isAnalyzing) ...[
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
      ],
    );
  }

  // ── Step 2 form ───────────────────────────────────────────────────────────

  Widget _buildStep2Form(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    return _aiFailed
        ? _buildFullForm(context, l10n, companyLocale)
        : _buildFastTrackForm(context, l10n, companyLocale);
  }

  Widget _buildFastTrackForm(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    final uiLocale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category
        AnimatedBuilder(
          animation: _shakeCategoryAnimation,
          child: Column(
            key: _categoryKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _requiredLabel(l10n.categoryLabel),
              const SizedBox(height: 8),
              DropdownMenu<int>(
                controller: _categoryController,
                expandedInsets: EdgeInsets.zero,
                hintText: l10n.selectCategory,
                inputDecorationTheme: _dropdownTheme(
                  isError: _hasAttemptedSubmit && _selectedCategoryId == null,
                ),
                dropdownMenuEntries: ExpenseCategory.orderedValues
                    .map((c) => DropdownMenuEntry<int>(
                          value: c.id,
                          label: c.labelForLocale(uiLocale),
                        ))
                    .toList(),
                onSelected: (v) => setState(() => _selectedCategoryId = v),
              ),
              if (_hasAttemptedSubmit && _selectedCategoryId == null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                  child: Text(
                    l10n.categoryRequired,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeCategoryAnimation.value, 0),
            child: child,
          ),
        ),
        const SizedBox(height: 16),

        // Note
        Text(
          l10n.noteLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 3,
          minLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 16),

        // AI Detected Details panel
        _buildAiDetectedPanel(context, l10n, companyLocale),
      ],
    );
  }

  Widget _buildAiDetectedPanel(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    final result = _analysisResult;
    final uiLocale = Localizations.localeOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.muted.withAlpha(77),
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (!_isModifying) ...[
                _buildAiBadgeSmall(l10n),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  l10n.newExpenseDetectedDetails,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isModifying
                    ? _undoAiModify
                    : () => setState(() {
                        _isModifying = true;
                        _isAiData = false;
                      }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isModifying ? Icons.undo : Icons.edit_outlined,
                      size: 12,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isModifying
                          ? l10n.newExpenseUndoAi
                          : l10n.newExpenseModify,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_isModifying)
            // Read-only 2-col summary
            _buildDetectedSummary(l10n, result, companyLocale)
          else
            // Editable fields
            _buildDetectedEditable(l10n, result, companyLocale, uiLocale),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          // Receipt # — read-only summary or editable matching AI detected pattern
          if (!_isModifying) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.receiptRefLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _receiptRefController.text.isEmpty
                      ? '—'
                      : _receiptRefController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
              ],
            ),
          ] else ...[
            _requiredLabel(l10n.receiptRefLabel),
            const SizedBox(height: 8),
            TextFormField(
              controller: _receiptRefController,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              decoration: const InputDecoration(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetectedSummary(
      AppLocalizations l10n,
      ReceiptAnalysisResult? result,
      String companyLocale) {
    final amountText = result?.amount != null && result?.currencyCode != null
        ? '${result!.amount!.toStringAsFixed(2)} ${result.currencyCode}'
        : result?.amount != null
            ? result!.amount!.toStringAsFixed(2)
            : '—';
    final dateText = result?.expenseDate != null
        ? DateTime.tryParse(result!.expenseDate!)
                ?.toCompanyDate(companyLocale) ??
            result.expenseDate!
        : '—';
    final merchantText = result?.merchantName ?? '—';

    Widget cell(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(l10n.amountLabel, amountText)),
            const SizedBox(width: 12),
            Expanded(child: cell(l10n.expenseDate, dateText)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cell(l10n.merchantLabel, merchantText)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetectedEditable(
      AppLocalizations l10n,
      ReceiptAnalysisResult? result,
      String companyLocale,
      Locale uiLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount + Currency + Date
        _buildAmountCurrencyDateRow(context, l10n, companyLocale),
        const SizedBox(height: 12),
        // Merchant full width
        _requiredLabel(l10n.merchantLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _merchantController,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          decoration: InputDecoration(
            errorText: _hasAttemptedSubmit &&
                    _merchantController.text.trim().isEmpty
                ? l10n.merchantRequired
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFullForm(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    final uiLocale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI failure warning
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppTheme.amber.withAlpha(25),
            border: Border.all(color: AppTheme.amber.withAlpha(128)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppTheme.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.newExpenseAiFailedWarning,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.foreground),
                ),
              ),
            ],
          ),
        ),

        // Receipt Reference — first field
        _requiredLabel(l10n.receiptRefLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _receiptRefController,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 16),

        // Amount + Currency + Date
        _buildAmountCurrencyDateRow(context, l10n, companyLocale),
        const SizedBox(height: 16),

        // Merchant
        _requiredLabel(l10n.merchantLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _merchantController,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          decoration: InputDecoration(
            errorText: _hasAttemptedSubmit &&
                    _merchantController.text.trim().isEmpty
                ? l10n.merchantRequired
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Category
        AnimatedBuilder(
          animation: _shakeCategoryAnimation,
          child: Column(
            key: _categoryKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _requiredLabel(l10n.categoryLabel),
              const SizedBox(height: 8),
              DropdownMenu<int>(
                controller: _categoryController,
                expandedInsets: EdgeInsets.zero,
                hintText: l10n.selectCategory,
                inputDecorationTheme: _dropdownTheme(
                  isError: _hasAttemptedSubmit && _selectedCategoryId == null,
                ),
                dropdownMenuEntries: ExpenseCategory.orderedValues
                    .map((c) => DropdownMenuEntry<int>(
                          value: c.id,
                          label: c.labelForLocale(uiLocale),
                        ))
                    .toList(),
                onSelected: (v) => setState(() => _selectedCategoryId = v),
              ),
              if (_hasAttemptedSubmit && _selectedCategoryId == null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                  child: Text(
                    l10n.categoryRequired,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeCategoryAnimation.value, 0),
            child: child,
          ),
        ),
        const SizedBox(height: 16),

        // Note
        Text(
          l10n.noteLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 3,
          minLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _buildAmountCurrencyDateRow(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountField(l10n),
          const SizedBox(height: 16),
          _buildCurrencyDropdown(l10n),
          const SizedBox(height: 16),
          _buildDateField(context, l10n, companyLocale),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAmountField(l10n)),
            const SizedBox(width: 12),
            Expanded(child: _buildCurrencyDropdown(l10n)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateField(context, l10n, companyLocale),
      ],
    );
  }

  Widget _buildAmountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredLabel(l10n.amountLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ExpenseAmountInputFormatter()],
          decoration: InputDecoration(
            errorText: _hasAttemptedSubmit &&
                    _amountController.text.trim().isEmpty
                ? l10n.amountRequired
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currencyLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          key: ValueKey(_selectedCurrencyCode),
          initialSelection: _selectedCurrencyCode,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.currencyPlaceholder,
          inputDecorationTheme: _dropdownTheme(),
          dropdownMenuEntries: ExpenseCurrency.values
              .map((c) => DropdownMenuEntry<String>(
                    value: c.code,
                    label: c.code,
                  ))
              .toList(),
          onSelected: (v) => setState(() => _selectedCurrencyCode = v),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, String companyLocale) async {
    final today = DateTime.now();
    final sixMonthsAgo = DateTime(today.year, today.month - 6, today.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: sixMonthsAgo,
      lastDate: today,
    );

    if (picked == null || !mounted) return;

    final iso = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    _dateController.text = _isoToDisplayDate(iso, companyLocale);
    setState(() {
      _selectedDate = picked;
      _dateInputError = null;
    });
  }

  Widget _buildDateField(
      BuildContext context, AppLocalizations l10n, String companyLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredLabel(l10n.expenseDate),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          focusNode: _dateFocusNode,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            _DateAutoFormatInputFormatter(companyLocale),
          ],
          decoration: InputDecoration(
            hintText: _dateFormatHint(companyLocale),
            errorText: _dateInputError,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              onPressed: () => _pickDate(context, companyLocale),
            ),
          ),
          onChanged: (value) {
            final parsed = _parseDateInput(value, companyLocale);
            if (parsed != null) setState(() => _selectedDate = parsed);
          },
        ),
      ],
    );
  }

  void _validateDateInput() {
    if (!mounted) return;
    final value = _dateController.text.trim();
    if (value.isEmpty) {
      setState(() => _dateInputError = null);
      return;
    }
    final companyLocale = ref.read(companyLocaleProvider);
    final parsed = _parseDateInput(value, companyLocale);
    final l10n = AppLocalizations.of(context)!;
    String? error;
    if (parsed == null) {
      error =
          '${l10n.expenseDateInvalidFormat} ${_dateFormatHint(companyLocale)}';
    } else {
      final today = DateTime.now();
      final sixMonthsAgo =
          DateTime(today.year, today.month - 6, today.day);
      if (parsed.isAfter(today)) {
        error = l10n.expenseDateInFuture;
      } else if (parsed.isBefore(sixMonthsAgo)) {
        error = l10n.expenseDateTooOld;
      }
    }
    setState(() {
      _dateInputError = error;
      if (parsed != null) _selectedDate = parsed;
    });
  }

  DateTime? _parseDateInput(String value, String companyLocale) {
    // Try ISO YYYY-MM-DD first
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    // Try locale-specific format
    final parts = value.split(RegExp(r'[\-./]'));
    if (parts.length != 3) return null;
    final nums = parts.map((p) => int.tryParse(p)).toList();
    if (nums.any((n) => n == null)) return null;
    final isHebrew = companyLocale.startsWith('he');
    // Hebrew: DD.MM.YYYY  |  English: MM/DD/YYYY
    final day = isHebrew ? nums[0]! : nums[1]!;
    final month = isHebrew ? nums[1]! : nums[0]!;
    final year = nums[2]!;
    if (year < 1900 || year > DateTime.now().year + 1) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _dateFormatHint(String companyLocale) =>
      companyLocale.startsWith('he') ? 'DD.MM.YYYY' : 'MM/DD/YYYY';

  String _isoToDisplayDate(String isoDate, String companyLocale) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    final sep = companyLocale.startsWith('he') ? '.' : '/';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return companyLocale.startsWith('he')
        ? '$day$sep$month$sep$year'
        : '$month$sep$day$sep$year';
  }

  Widget _buildActionButtons(AppLocalizations l10n, BuildContext context) {
    final submitButton = ElevatedButton(
      onPressed: (_canAttemptSubmit && !_isSubmitting) ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _canSubmit ? AppTheme.success : null,
        foregroundColor: _canSubmit ? Colors.white : null,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.finish),
    );

    final errorRow = _submitError != null
        ? Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppTheme.destructive),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _submitError!,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.destructive),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          errorRow,
          submitButton,
        ],
      ),
    );
  }

  Widget _requiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.foreground,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadgeSmall(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(230),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            l10n.newExpenseAiBadgeLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedReceiptRow(
      BuildContext context, AppLocalizations l10n) {
    final icon = _isPdf ? Icons.picture_as_pdf : Icons.image_outlined;
    final label = _filename ?? (_isPdf ? 'PDF' : l10n.newExpenseUploadTitle);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        color: AppTheme.card,
      ),
      padding: const EdgeInsetsDirectional.only(
          start: 12, end: 4, top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.mutedForeground),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full, size: 18),
            tooltip: l10n.newExpenseExpandImage,
            onPressed: _isPdf
                ? (_pdfBlobUrl != null
                    ? () => web.window.open(_pdfBlobUrl!, '_blank')
                    : null)
                : () => _showFullScreenImage(context),
            color: AppTheme.mutedForeground,
            padding: const EdgeInsets.all(8),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: _resetToUpload,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppTheme.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.newExpenseReplaceFile,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.foreground),
            ),
          ),
        ],
      ),
    );
  }

  InputDecorationTheme _dropdownTheme({bool isError = false}) {
    final borderSide = isError
        ? const BorderSide(color: AppTheme.destructive, width: 1.5)
        : const BorderSide(color: AppTheme.border);
    return InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppTheme.mutedForeground),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  // chrome: scrollPad(48)+backBtn(36)+gap(8)+cardBorder(2)+
                  //         cardPad(32)+stepIndicator(46)+stepGap(32)+continueArea(66)
                  const mobileChrome = 270.0;
                  // fileInfo row adds ~44px in preview state
                  final uploadHeight = context.isMobile
                      ? ((availableHeight - mobileChrome) * 0.85)
                          .clamp(120.0, 600.0)
                      : (availableHeight * 0.6).clamp(320.0, 600.0);
                  // Same height as upload zone — avoids jarring resize on file select.
                  // File-info row + Continue button extend below (tiny scroll acceptable).
                  final previewHeight = uploadHeight;
                  return SingleChildScrollView(
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
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(context.isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (context.isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.newExpense,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.foreground,
                                      ),
                                    ),
                                    Expanded(
                                      child: ExpenseStepIndicator(
                                          currentStep: _currentStep),
                                    ),
                                  ],
                                )
                              else
                                ExpenseStepIndicator(
                                    currentStep: _currentStep),
                              const SizedBox(height: 24),
                              if (_currentStep == 0) ...[
                                if (_fileBytes == null)
                                  _buildUploadZone(l10n, uploadHeight)
                                else
                                  _buildPreview(
                                      context, l10n, previewHeight),
                                if (!_isAnalyzing) ...[
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment:
                                        AlignmentDirectional.centerEnd,
                                    child: ElevatedButton(
                                      onPressed: _fileBytes != null
                                          ? _analyze
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _fileBytes != null
                                            ? AppTheme.success
                                            : null,
                                        foregroundColor: _fileBytes != null
                                            ? Colors.white
                                            : null,
                                      ),
                                      child: Text(l10n.continueButton),
                                    ),
                                  ),
                                ],
                              ] else if (context.isDesktop) ...[
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildStep2Form(
                                          context, l10n, companyLocale),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: ExpenseCreateImagePanel(
                                        fileBytes: _fileBytes!,
                                        isPdf: _isPdf,
                                        pdfViewType: _pdfViewType,
                                        aiFailed: _aiFailed,
                                        hideAiBadge: _isModifying,
                                        onExpand: _isPdf
                                            ? (_pdfBlobUrl != null
                                                ? () => web.window.open(
                                                    _pdfBlobUrl!, '_blank')
                                                : null)
                                            : () => _showFullScreenImage(
                                                context),
                                        onDownload: _downloadFile,
                                        onReplace: _resetToUpload,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildActionButtons(l10n, context),
                              ] else ...[
                                _buildCollapsedReceiptRow(context, l10n),
                                const SizedBox(height: 16),
                                _buildStep2Form(
                                    context, l10n, companyLocale),
                                const SizedBox(height: 16),
                                _buildActionButtons(l10n, context),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
                },
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _CornerBracketPainter extends CustomPainter {
  final bool top;
  final bool start;
  final Color color;
  final double thickness;

  const _CornerBracketPainter({
    required this.top,
    required this.start,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;

    if (top && start) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
    } else if (top && !start) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && start) {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
    } else {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.color != color || old.top != top || old.start != start;
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

/// Auto-inserts locale-specific date separators as the user types digits.
/// Hebrew: DD.MM.YYYY  |  English: MM/DD/YYYY
class _DateAutoFormatInputFormatter extends TextInputFormatter {
  final String companyLocale;
  _DateAutoFormatInputFormatter(this.companyLocale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits
    final digits =
        newValue.text.replaceAll(RegExp(r'[^\d]'), '').substring(
            0,
            newValue.text
                    .replaceAll(RegExp(r'[^\d]'), '')
                    .length
                    .clamp(0, 8));
    final sep = companyLocale.startsWith('he') ? '.' : '/';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write(sep);
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
