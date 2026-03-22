import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'screen_imports.dart';
import '../models/expense_detail.dart';
import '../models/expense_category.dart';
import '../models/expense_currency.dart';
import '../models/update_expense_request.dart';
import '../providers/expense_provider.dart';
import '../services/excel_export_service.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/expense_amount_input_formatter.dart';

class EmployeeExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;
  final bool isManagerMode;

  /// When true: all fields are locked, all action buttons are hidden.
  /// Use this when displaying the screen inside a modal from another screen.
  final bool readOnly;

  /// When true: renders only the expense content — no AppHeader, AppFooter,
  /// or navigation guard. Use when embedding inside a Dialog.
  final bool dialogMode;

  const EmployeeExpenseDetailScreen({
    super.key,
    required this.expenseId,
    this.isManagerMode = false,
    this.readOnly = false,
    this.dialogMode = false,
  });

  @override
  ConsumerState<EmployeeExpenseDetailScreen> createState() =>
      _EmployeeExpenseDetailScreenState();
}

class _EmployeeExpenseDetailScreenState
    extends ConsumerState<EmployeeExpenseDetailScreen>
    with FormBehaviorMixin {
  ExpenseDetail? _expense;
  bool _isLoading = true;
  bool _isNotFound = false;
  String? _loadError;
  bool _isClosed = false;

  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiptRefController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  String? _selectedCurrencyCode;

  bool _isAiData = false;
  bool _isModifying = false;

  bool _isSaving = false;
  String? _saveError;

  /// Manager-mode: fields start locked; toggled by the Edit button.
  bool _isEditingEnabled = false;

  bool get _isEditable {
    if (widget.readOnly) return false;
    if (widget.isManagerMode) return _isEditingEnabled && !_isClosed;
    return _expense?.isPending == true && !_isClosed;
  }

  bool get _canSave =>
      _amountController.text.trim().isNotEmpty &&
      _selectedCategoryId != null &&
      _merchantController.text.trim().isNotEmpty &&
      _selectedDate != null;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _merchantController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpense());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _receiptRefController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final service = ref.read(expenseServiceProvider);
      final expense = await service.getExpenseById(widget.expenseId);
      _initForm(expense);
      if (mounted) setState(() { _expense = expense; _isLoading = false; });
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isNotFound = true; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoading = false; });
    }
  }

  void _initForm(ExpenseDetail expense) {
    _amountController.text = expense.amount != null
        ? NumberFormat('#,##0.##', 'en').format(expense.amount!)
        : '';
    _merchantController.text = expense.merchantName ?? '';
    _noteController.text = expense.note ?? '';
    _receiptRefController.text = expense.receiptRef ?? '';
    _selectedDate = expense.expenseDate;
    _selectedCategoryId = expense.categoryId;
    _selectedCurrencyCode = expense.currencyCode ?? 'ILS';
    _isAiData = expense.isAiData;
    _isModifying = false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Managers can review/correct old expenses — use a 5-year window.
    final firstDate = widget.isManagerMode
        ? now.subtract(const Duration(days: 1825))
        : now.subtract(const Duration(days: 180));
    // Guard: initialDate must not be before firstDate (release builds skip asserts).
    final initialDate = _selectedDate != null && _selectedDate!.isAfter(firstDate)
        ? _selectedDate!
        : firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    // Capture context-dependent values before any await.
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.updateExpense(
        widget.expenseId,
        UpdateExpenseRequest(
          expenseDate: _selectedDate!.toIso8601String().split('T').first,
          categoryId: _selectedCategoryId!,
          merchantName: _merchantController.text.trim().isEmpty
              ? null : _merchantController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null : _noteController.text.trim(),
          amount: double.tryParse(_amountController.text.replaceAll(',', '')),
          currencyCode: _selectedCurrencyCode,
          receiptRef: _receiptRefController.text.trim().isEmpty
              ? null : _receiptRefController.text.trim(),
          isAiData: _isAiData,
        ),
      );
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      navigator.pop();
    } on ExpenseClosedException {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isClosed = true;
          _saveError = l10n.expenseClosedError;
        });
      }
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isSaving = false; _isNotFound = true; });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  Future<void> _approve() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      // Only save form edits if the manager actively enabled editing
      if (_isEditingEnabled) {
        await service.updateExpense(
          widget.expenseId,
          UpdateExpenseRequest(
            expenseDate: _selectedDate!.toIso8601String().split('T').first,
            categoryId: _selectedCategoryId!,
            merchantName: _merchantController.text.trim().isEmpty
                ? null : _merchantController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null : _noteController.text.trim(),
            amount: double.tryParse(_amountController.text.replaceAll(',', '')),
            currencyCode: _selectedCurrencyCode,
            receiptRef: _receiptRefController.text.trim().isEmpty
                ? null : _receiptRefController.text.trim(),
            isAiData: _isAiData,
          ),
        );
      }
      await service.approveExpense(widget.expenseId);
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      navigator.pop();
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isSaving = false; _isNotFound = true; });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  Future<void> _decline() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.declineExpense(widget.expenseId);
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      navigator.pop();
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isSaving = false; _isNotFound = true; });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        required ? '$text *' : text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.foreground,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool enabled = true,
    bool monospace = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: monospace ? 'monospace' : null,
            color: enabled ? AppTheme.foreground : AppTheme.mutedForeground,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: enabled ? null : AppTheme.muted.withAlpha(77),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String companyLocale, {bool required = false, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        InkWell(
          onTap: enabled ? _pickDate : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
              color: enabled ? null : AppTheme.muted.withAlpha(77),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate?.toCompanyDate(companyLocale) ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? AppTheme.foreground : AppTheme.mutedForeground,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: enabled ? AppTheme.mutedForeground : AppTheme.mutedForeground.withAlpha(128)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n, Locale uiLocale, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.categoryLabel, required: true),
        DropdownMenu<int>(
          initialSelection: _selectedCategoryId,
          enabled: enabled,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.selectCategory,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: !enabled ? AppTheme.muted.withAlpha(77) : null,
          ),
          dropdownMenuEntries: ExpenseCategory.orderedValues
              .map((cat) => DropdownMenuEntry<int>(
                    value: cat.id,
                    label: cat.labelForLocale(uiLocale),
                  ))
              .toList(),
          onSelected: enabled
              ? (value) => setState(() => _selectedCategoryId = value)
              : null,
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(AppLocalizations l10n, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.currencyLabel, required: true),
        DropdownMenu<String>(
          initialSelection: _selectedCurrencyCode,
          enabled: enabled,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.currencyPlaceholder,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: !enabled ? AppTheme.muted.withAlpha(77) : null,
          ),
          dropdownMenuEntries: ExpenseCurrency.values
              .map((c) =>
                  DropdownMenuEntry<String>(value: c.code, label: c.displayLabel))
              .toList(),
          onSelected: enabled
              ? (value) => setState(() => _selectedCurrencyCode = value)
              : null,
        ),
      ],
    );
  }

  Widget _buildAmountCurrencyDateRow(
      AppLocalizations l10n, String companyLocale, {bool enabled = true}) {
    final isNarrow = context.isNarrow;
    final amountField = _buildTextField(
      l10n.amountLabel,
      _amountController,
      required: true,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ExpenseAmountInputFormatter()],
    );
    final currencyField = _buildCurrencyDropdown(l10n, enabled: enabled);
    final dateField = _buildDateField(
      l10n.expenseDate,
      companyLocale,
      required: true,
      enabled: enabled,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          amountField,
          const SizedBox(height: 12),
          currencyField,
          const SizedBox(height: 12),
          dateField,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: amountField),
        const SizedBox(width: 12),
        Expanded(child: currencyField),
        const SizedBox(width: 12),
        Expanded(child: dateField),
      ],
    );
  }

  Widget _buildAiChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(230),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          SizedBox(width: 4),
          Text('AI',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAiDetectedPanel(
      AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.muted.withAlpha(77),
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAiChip(),
              const SizedBox(width: 8),
              Text(l10n.newExpenseDetectedDetails,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_isEditable)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _isModifying = !_isModifying;
                    if (_isModifying) _isAiData = false;
                  }),
                  icon: Icon(
                      _isModifying
                          ? Icons.undo_outlined
                          : Icons.edit_outlined,
                      size: 14),
                  label: Text(
                      _isModifying ? l10n.newExpenseUndoAi : l10n.newExpenseModify),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isModifying) ...[
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (_expense!.amount != null)
                  _SummaryTile(
                    label: l10n.amountLabel,
                    value: _expense!.amount!.toCurrency(
                        companyLocale, _expense!.currencyCode ?? 'ILS'),
                  ),
                _SummaryTile(
                    label: l10n.expenseDate,
                    value: _expense!.expenseDate.toCompanyDate(companyLocale)),
                if (_expense!.merchantName != null)
                  _SummaryTile(
                      label: l10n.merchantLabel,
                      value: _expense!.merchantName!),
                if (_expense!.receiptRef != null)
                  _SummaryTile(
                      label: l10n.receiptRefLabel,
                      value: _expense!.receiptRef!),
              ],
            ),
          ] else ...[
            _buildAmountCurrencyDateRow(l10n, companyLocale, enabled: _isEditable && !_isSaving),
            const SizedBox(height: 12),
            _buildTextField(l10n.merchantLabel, _merchantController,
                required: true, enabled: _isEditable && !_isSaving),
            const SizedBox(height: 12),
            _buildTextField(l10n.receiptRefLabel, _receiptRefController,
                monospace: true, enabled: _isEditable && !_isSaving),
          ],
        ],
      ),
    );
  }

  Widget _buildFastTrackForm(
      AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryDropdown(l10n, uiLocale,
            enabled: _isEditable && !_isSaving),
        const SizedBox(height: 16),
        _buildTextField(l10n.noteLabel, _noteController,
            maxLines: 3, enabled: _isEditable && !_isSaving),
        const SizedBox(height: 16),
        _buildAiDetectedPanel(l10n, companyLocale, uiLocale),
      ],
    );
  }

  Widget _buildFullForm(
      AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    final enabled = _isEditable && !_isSaving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(l10n.receiptRefLabel, _receiptRefController,
            monospace: true, enabled: enabled),
        const SizedBox(height: 16),
        _buildAmountCurrencyDateRow(l10n, companyLocale, enabled: enabled),
        const SizedBox(height: 16),
        _buildTextField(l10n.merchantLabel, _merchantController,
            required: true, enabled: enabled),
        const SizedBox(height: 16),
        _buildCategoryDropdown(l10n, uiLocale, enabled: enabled),
        const SizedBox(height: 16),
        // Manager cannot edit notes
        _buildTextField(l10n.noteLabel, _noteController,
            maxLines: 3,
            enabled: widget.isManagerMode ? false : enabled),
      ],
    );
  }

  Widget _buildManagerInfoHeader(AppLocalizations l10n, String companyLocale) {
    final expense = _expense;
    if (expense == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.createdByName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                expense.createdAt.toCompanyDate(companyLocale),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (!_isEditingEnabled && !widget.readOnly)
          TextButton.icon(
            onPressed: () => setState(() => _isEditingEnabled = true),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: Text(l10n.edit),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
      ],
    );
  }

  /// Approve / Decline buttons — manager only. Always right-aligned.
  Widget _buildManagerApproveDeclineRow(AppLocalizations l10n) {
    if (widget.readOnly) return const SizedBox.shrink();
    final expense = _expense;
    if (expense == null) return const SizedBox.shrink();
    final statusId = expense.expenseStatusId;
    final showApprove = statusId != 2;
    final showDecline = statusId != 3;
    if (!showApprove && !showDecline) return const SizedBox.shrink();

    const spinner = SizedBox(
      width: 14, height: 14,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_saveError != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppTheme.destructive),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_saveError!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.destructive)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showApprove)
              FilledButton.icon(
                onPressed: _isSaving ? null : _approve,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving ? spinner : const Icon(Icons.check, size: 16),
                label: Text(l10n.approve),
              ),
            if (showApprove && showDecline) const SizedBox(width: 12),
            if (showDecline)
              FilledButton.icon(
                onPressed: _isSaving ? null : _decline,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.destructive,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close, size: 16),
                label: Text(l10n.decline),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    if (widget.readOnly) return const SizedBox.shrink();
    // Manager: Update button shown only when editing is enabled
    if (widget.isManagerMode) {
      if (!_isEditingEnabled) return const SizedBox.shrink();
      return FilledButton.icon(
        onPressed: _canSave && !_isSaving ? _save : null,
        icon: _isSaving
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_outlined, size: 16),
        label: Text(l10n.updateExpenseDetails),
      );
    }

    if (!_isEditable) return const SizedBox.shrink();
    final isNarrow = context.isNarrow;

    final errorRow = _saveError != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppTheme.destructive),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_saveError!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.destructive)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          )
        : null;

    final saveBtn = FilledButton.icon(
      onPressed: _canSave && !_isSaving ? _save : null,
      icon: _isSaving
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_outlined, size: 16),
      label: Text(l10n.updateExpenseDetails),
    );
    final discardBtn = OutlinedButton(
      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
      child: Text(l10n.discard),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorRow != null) errorRow,
        if (isNarrow) ...[
          saveBtn,
          const SizedBox(height: 8),
          discardBtn,
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              discardBtn,
              const SizedBox(width: 12),
              saveBtn,
            ],
          ),
      ],
    );
  }

  Widget _buildReceiptSection(AppLocalizations l10n, {double height = 400}) {
    final imageUrl = _expense?.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppTheme.mutedForeground),
              const SizedBox(height: 8),
              Text(l10n.noReceipt,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.mutedForeground)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => const Center(
              child: Icon(Icons.broken_image,
                  size: 48, color: AppTheme.mutedForeground),
            ),
          ),
          // Top-end overlay
          PositionedDirectional(
            top: 8,
            end: 8,
            child: Row(
              children: [
                _buildOverlayButton(
                  icon: Icons.open_in_full,
                  onTap: () => _showExpandDialog(imageUrl),
                ),
                if (context.isDesktop) ...[
                  const SizedBox(width: 4),
                  _buildOverlayButton(
                    icon: Icons.download_outlined,
                    onTap: () {
                      final filename = imageUrl.split('/').last.split('?').first;
                      ExcelExportService.downloadUrl(imageUrl, filename.isEmpty ? 'receipt' : filename);
                    },
                  ),
                ],
              ],
            ),
          ),
          // Replace receipt (desktop + pending only, not for manager)
          if (_isEditable && context.isDesktop && !widget.isManagerMode)
            PositionedDirectional(
              bottom: 8,
              start: 8,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.image_outlined, size: 14),
                label: Text(l10n.newExpenseReplaceReceipt),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.card.withAlpha(204),
                  minimumSize: const Size(0, 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                  side: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.card.withAlpha(204),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppTheme.foreground),
      ),
    );
  }

  void _showExpandDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox(
          width: context.screenWidth * 0.98,
          height: MediaQuery.of(context).size.height * 0.98,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.card.withAlpha(204),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.expenseNotFound,
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.mutedForeground)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToDashboard),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_loadError ?? l10n.anErrorOccurred,
              style: const TextStyle(color: AppTheme.destructive)),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: _loadExpense, child: Text(l10n.continueButton)),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_isNotFound) return _buildNotFound(l10n);
    if (_loadError != null) return _buildError(l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ConstrainedContent(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.dialogMode)
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(l10n.backToDashboard),
              ),
            if (!widget.dialogMode) const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(context.isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.expenseDetail,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.mutedForeground)),
                        ),
                        if (widget.dialogMode)
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (context.isDesktop)
                      _buildDesktopLayout(l10n, companyLocale, uiLocale)
                    else
                      _buildMobileLayout(l10n, companyLocale, uiLocale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    final uiLocale = Localizations.localeOf(context);

    if (widget.dialogMode) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: _buildContent(l10n, companyLocale, uiLocale),
      );
    }

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(child: _buildContent(l10n, companyLocale, uiLocale)),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    final form = !_isAiData
        ? _buildFullForm(l10n, companyLocale, uiLocale)
        : _buildFastTrackForm(l10n, companyLocale, uiLocale);

    // IntrinsicHeight lets the right column stretch to the left column's
    // height so the Spacer can push approve/decline to the bottom-right.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isManagerMode) ...[
                  _buildManagerInfoHeader(l10n, companyLocale),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                form,
                const SizedBox(height: 24),
                _buildActionButtons(l10n),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildReceiptSection(l10n),
                if (widget.isManagerMode) ...[
                  const Spacer(),
                  _buildManagerApproveDeclineRow(l10n),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    final form = !_isAiData
        ? _buildFullForm(l10n, companyLocale, uiLocale)
        : _buildFastTrackForm(l10n, companyLocale, uiLocale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReceiptSection(l10n, height: 192),
        if (widget.isManagerMode) ...[
          const SizedBox(height: 16),
          _buildManagerApproveDeclineRow(l10n),
        ],
        const SizedBox(height: 16),
        if (widget.isManagerMode) ...[
          _buildManagerInfoHeader(l10n, companyLocale),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
        form,
        const SizedBox(height: 24),
        _buildActionButtons(l10n),
      ],
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedForeground)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground)),
      ],
    );
  }
}
