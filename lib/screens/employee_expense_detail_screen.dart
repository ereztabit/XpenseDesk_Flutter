import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'screen_imports.dart';
import '../models/expense_detail.dart';
import '../models/expense_sheet_status.dart';
import '../models/expense_summary.dart';
import '../widgets/ai_badge.dart';
import '../widgets/app_button.dart';
import '../models/expense_category.dart';
import '../providers/company_provider.dart';
import '../models/update_expense_request.dart';
import '../providers/employee_dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../services/excel_export_service.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/sheet_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/expense_amount_input_formatter.dart';
import '../utils/conversion_preview_controller.dart';
import '../widgets/expenses/conversion_preview_label.dart';
import '../widgets/expenses/delete_expense_dialog.dart';
import '../widgets/expenses/dev_scan_record_button.dart';
import '../widgets/expenses/expense_modify_image_panel.dart';
import '../widgets/last_action_confirm_dialog.dart';
import '../widgets/shake_on_demand.dart';

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
  late final ConversionPreviewController _conversion;

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  String? _selectedCurrencyCode;

  bool _isAiData = false;
  bool _isModifying = false;

  bool _isSaving = false;
  String? _saveError;

  // Saving with a mandatory field empty shakes it, reddens it and scrolls it
  // into view — same treatment as the New Expense wizard.
  bool _hasAttemptedSave = false;
  final _amountKey = GlobalKey();
  final _dateKey = GlobalKey();
  int _amountShakeToken = 0;
  int _dateShakeToken = 0;

  /// Manager-mode: fields start locked; toggled by the Edit button.
  bool _isEditingEnabled = false;

  // Baseline of the loaded expense, for dirty detection (#8).
  double? _initialAmount;
  String _initialMerchant = '';
  String _initialNote = '';
  String _initialReceiptRef = '';
  DateTime? _initialDate;
  int? _initialCategoryId;
  String? _initialCurrencyCode;
  bool _initialIsAiData = false;

  /// True when the parent sheet is finalised (Approved) — locked for everyone,
  /// including the manager escape hatch.
  bool get _isSheetApproved =>
      _expense?.expenseSheetStatusId == ExpenseSheetStatus.approved.id;

  bool get _isEditable {
    if (widget.readOnly || _isClosed) return false;
    if (widget.isManagerMode) return _isEditingEnabled && !_isSheetApproved;
    final expense = _expense;
    if (expense == null) return false;
    final sheetStatusId = expense.expenseSheetStatusId;
    // Older payloads without sheet linkage: fall back to pending-only.
    if (sheetStatusId == null) return expense.isPending;
    // The sheet status gates editability: a Pending expense on a Submitted
    // sheet is read-only; Draft and Declined sheets allow edits per the matrix.
    return SheetPermissions.canEditExpense(
      sheetStatusId: sheetStatusId,
      expenseStatusId: expense.expenseStatusId,
      isManager: false,
    );
  }

  /// Amount and date are the only mandatory fields — merchant, category, note
  /// and receipt # are optional (an unset category saves as "Other").
  bool get _canSave =>
      _amountController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      // Block save while a conversion is in flight or has failed (rules 3/5).
      _conversion.canSave;

  /// True when any field differs from the loaded baseline (#8). Gates the
  /// save/update button so an unchanged form cannot be submitted.
  bool get _isDirty {
    final currentAmount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    return currentAmount != _initialAmount ||
        _merchantController.text != _initialMerchant ||
        _noteController.text != _initialNote ||
        _receiptRefController.text != _initialReceiptRef ||
        _selectedDate != _initialDate ||
        _selectedCategoryId != _initialCategoryId ||
        _selectedCurrencyCode != _initialCurrencyCode ||
        _isAiData != _initialIsAiData;
  }

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    _conversion = ConversionPreviewController(ref.read(expenseServiceProvider));
    _conversion.addListener(_onConversionChanged);
    _amountController.addListener(() => setState(() {}));
    _amountController.addListener(_evaluateConversion);
    _merchantController.addListener(() => setState(() {}));
    _noteController.addListener(() => setState(() {}));
    _receiptRefController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpense());
  }

  void _onConversionChanged() {
    if (mounted) setState(() {});
  }

  /// Push the current amount/currency/date into the live conversion preview.
  void _evaluateConversion() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    _conversion.evaluate(
      currency: _selectedCurrencyCode,
      amount: amount,
      date: _selectedDate,
      baseCurrency: ref.read(companyBaseCurrencyProvider),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _receiptRefController.dispose();
    _conversion.removeListener(_onConversionChanged);
    _conversion.dispose();
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
    // The editable amount is what the user actually entered, in their currency
    // (dynamicAmount) — NOT the server-booked base-currency value (amount).
    final editableAmount = expense.dynamicAmount ?? expense.amount;
    _amountController.text = editableAmount != null
        ? NumberFormat('#,##0.##', 'en').format(editableAmount)
        : '';
    _merchantController.text = expense.merchantName ?? '';
    _noteController.text = expense.note ?? '';
    _receiptRefController.text = expense.receiptRef ?? '';
    _selectedDate = expense.expenseDate;
    _selectedCategoryId = expense.categoryId;
    _selectedCurrencyCode =
        expense.currencyCode ?? expense.baseCurrencyCode ?? 'ILS';
    _isAiData = expense.isAiData;
    _isModifying = false;

    // Baseline snapshot for dirty detection (#8).
    _initialAmount = editableAmount;
    _initialMerchant = _merchantController.text;
    _initialNote = _noteController.text;
    _initialReceiptRef = _receiptRefController.text;
    _initialDate = expense.expenseDate;
    _initialCategoryId = expense.categoryId;
    _initialCurrencyCode = _selectedCurrencyCode;
    _initialIsAiData = expense.isAiData;

    // Fields are set above in amount-then-currency/date order, so the amount
    // listener fired with stale currency/date — re-evaluate with final values.
    _evaluateConversion();
  }

  /// Manager-mode cancel: restore the loaded values and exit edit mode.
  void _cancelManagerEdit() {
    final expense = _expense;
    if (expense != null) _initForm(expense);
    setState(() => _isEditingEnabled = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Managers can review/correct old expenses — use a 5-year window.
    // Employees can report up to 12 months back (matches the server policy).
    final firstDate = widget.isManagerMode
        ? now.subtract(const Duration(days: 1825))
        : DateTime(now.year - 1, now.month, now.day);
    // Clamp initialDate into [firstDate, now]; an out-of-range initialDate makes
    // showDatePicker assert and the calendar fails to load.
    var initialDate = _selectedDate ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(now)) initialDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _evaluateConversion();
    }
  }

  /// Loads the parent sheet's expenses (cached if Sheet Review / dashboard
  /// already fetched it, else forces the fetch). Returns null when it can't be
  /// resolved so callers can skip the warning rather than block a valid action.
  Future<List<ExpenseSummary>?> _loadSheetExpenses(String sheetId) async {
    try {
      final cached = ref.read(sheetDetailProvider(sheetId)).asData?.value;
      final sheet = cached ?? await ref.read(sheetDetailProvider(sheetId).future);
      return sheet?.expenses;
    } catch (_) {
      return null;
    }
  }

  /// Reddens, shakes and scrolls to whichever mandatory field is still empty,
  /// instead of leaving the user with a button that silently does nothing.
  void _flagMissingMandatoryFields() {
    final amountMissing = _amountController.text.trim().isEmpty;

    setState(() {
      _hasAttemptedSave = true;
      if (amountMissing) _amountShakeToken++;
      if (_selectedDate == null) _dateShakeToken++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = (amountMissing ? _amountKey : _dateKey).currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_canSave) {
      _flagMissingMandatoryFields();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final expense = _expense;
    // Pre-resubmit warning (employee): saving the last Declined expense on a
    // Declined sheet resets it to Pending and re-submits the sheet to the manager.
    var willResubmit = false;
    if (!widget.isManagerMode &&
        expense?.expenseSheetId != null &&
        expense!.expenseSheetStatusId == ExpenseSheetStatus.declined.id &&
        expense.expenseStatusId == 3) {
      final siblings = await _loadSheetExpenses(expense.expenseSheetId!);
      if (siblings != null &&
          SheetExpenseBuckets.isLastDeclinedExpense(siblings)) {
        if (!mounted) return;
        final proceed = await LastActionConfirmDialog.show(
          context,
          title: l10n.lastActionTitle,
          body: l10n.lastActionResubmitBody,
        );
        if (!proceed || !mounted) return;
        willResubmit = true;
      }
    }

    if (!mounted) return;
    setState(() { _isSaving = true; _saveError = null; });

    // Capture context-dependent values before any await.
    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.updateExpense(
        widget.expenseId,
        UpdateExpenseRequest(
          expenseDate: _selectedDate!.toIso8601String().split('T').first,
          categoryId: _selectedCategoryId ?? ExpenseCategory.other.id,
          merchantName: _merchantController.text.trim().isEmpty
              ? null : _merchantController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null : _noteController.text.trim(),
          dynamicAmount:
              double.tryParse(_amountController.text.replaceAll(',', '')),
          currencyCode: _selectedCurrencyCode,
          receiptRef: _receiptRefController.text.trim().isEmpty
              ? null : _receiptRefController.text.trim(),
          isAiData: _isAiData,
        ),
      );
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      // The last declined line just re-submitted the sheet — it is no longer the
      // employee's to act on. Drop the dashboard selection so it re-defaults to
      // the current draft instead of lingering on the now-submitted sheet.
      if (willResubmit) {
        ref.read(selectedSheetIdProvider.notifier).set(null);
      }
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
    } on ExchangeRateUnavailableException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = AppLocalizations.of(context)!.expenseExchangeRateUnavailable;
      });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  Future<void> _approve() async {
    if (_isSaving) return;
    // Approving with editing on saves the form first — the same mandatory
    // fields apply, and an empty date would blow up on `_selectedDate!` below.
    if (_isEditingEnabled && !_canSave) {
      _flagMissingMandatoryFields();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final expense = _expense;
    // Pre-finalize warning (manager): approving the last not-yet-approved line
    // on a non-terminal sheet auto-finalizes the whole sheet to Approved —
    // the one irreversible moment, so it gets an explicit confirm.
    if (expense?.expenseSheetId != null &&
        (expense!.expenseSheetStatusId ==
                ExpenseSheetStatus.waitingForApproval.id ||
            expense.expenseSheetStatusId ==
                ExpenseSheetStatus.declined.id)) {
      final siblings = await _loadSheetExpenses(expense.expenseSheetId!);
      if (siblings != null &&
          SheetExpenseBuckets.approveFinalizesSheet(
              siblings, widget.expenseId)) {
        if (!mounted) return;
        final proceed = await LastActionConfirmDialog.show(
          context,
          title: l10n.lastActionTitle,
          body: l10n.lastActionApproveBody,
        );
        if (!proceed || !mounted) return;
      }
    }

    if (!mounted) return;
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
            categoryId: _selectedCategoryId ?? ExpenseCategory.other.id,
            merchantName: _merchantController.text.trim().isEmpty
                ? null : _merchantController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null : _noteController.text.trim(),
            dynamicAmount:
                double.tryParse(_amountController.text.replaceAll(',', '')),
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
    } on ExchangeRateUnavailableException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = AppLocalizations.of(context)!.expenseExchangeRateUnavailable;
      });
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
    } on ExchangeRateUnavailableException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = AppLocalizations.of(context)!.expenseExchangeRateUnavailable;
      });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  /// Manager delete (escape hatch). Confirms via the shared dialog; on success
  /// the expense is gone, so leave the detail screen — the sheet review
  /// refreshes on return.
  Future<void> _delete() async {
    final deleted = await DeleteExpenseDialog.show(context, widget.expenseId);
    if (deleted && mounted) {
      Navigator.of(context).pop();
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
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        TextFormField(
          controller: controller,
          // Read-only (not disabled) when not editable: the value stays
          // selectable/copyable while remaining non-editable. A disabled field
          // can't be selected at all (and SelectionArea skips editable widgets).
          readOnly: !enabled,
          enableInteractiveSelection: true,
          maxLines: maxLines,
          inputFormatters: enabled ? inputFormatters : null,
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
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String companyLocale,
      {bool required = false, bool enabled = true, String? errorText}) {
    // Hand-rolled field (it opens a picker rather than taking keystrokes), so
    // the error border and message that InputDecoration would give us for free
    // are built here.
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
              border: Border.all(
                color: errorText != null ? AppTheme.destructive : AppTheme.border,
              ),
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 8),
            child: Text(
              errorText,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.destructive),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n, Locale uiLocale, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.categoryLabel),
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
          dropdownMenuEntries: ref
              .watch(trackedCurrenciesProvider)
              .map((c) => DropdownMenuEntry<String>(
                  value: c.currencyCode, label: c.displayLabel))
              .toList(),
          onSelected: enabled
              ? (value) {
                  setState(() => _selectedCurrencyCode = value);
                  _evaluateConversion();
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildAmountCurrencyDateRow(
      AppLocalizations l10n, String companyLocale, {bool enabled = true}) {
    final isNarrow = context.isNarrow;
    final amountField = ShakeOnDemand(
      token: _amountShakeToken,
      child: KeyedSubtree(
        key: _amountKey,
        child: _buildTextField(
          l10n.amountLabel,
          _amountController,
          required: true,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ExpenseAmountInputFormatter()],
          errorText: _hasAttemptedSave && _amountController.text.trim().isEmpty
              ? l10n.amountRequired
              : null,
        ),
      ),
    );
    final currencyField = _buildCurrencyDropdown(l10n, enabled: enabled);
    final dateField = ShakeOnDemand(
      token: _dateShakeToken,
      child: KeyedSubtree(
        key: _dateKey,
        child: _buildDateField(
          l10n.expenseDate,
          companyLocale,
          required: true,
          enabled: enabled,
          errorText: _hasAttemptedSave && _selectedDate == null
              ? l10n.expenseDateRequired
              : null,
        ),
      ),
    );
    final conversionField = ConversionPreviewLabel(
      controller: _conversion,
      companyLocale: companyLocale,
      baseCurrency: ref.read(companyBaseCurrencyProvider),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          amountField,
          const SizedBox(height: 12),
          currencyField,
          conversionField,
          const SizedBox(height: 12),
          dateField,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: amountField),
            const SizedBox(width: 12),
            Expanded(child: currencyField),
            const SizedBox(width: 12),
            Expanded(child: dateField),
          ],
        ),
        conversionField,
      ],
    );
  }

  Widget _buildAiChip() => const AiBadge(variant: AiBadgeVariant.chip);

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
                if (_expense!.amount != null) ...[
                  // Foreign expense: show what the user spent (original
                  // currency) as primary, booked base value as secondary.
                  _SummaryTile(
                    label: l10n.amountLabel,
                    value: _expense!.isForeign && _expense!.dynamicAmount != null
                        ? _expense!.dynamicAmount!.toCurrency(companyLocale,
                            _expense!.currencyCode ??
                                _expense!.baseCurrencyCode ??
                                ref.read(companyBaseCurrencyProvider))
                        : _expense!.amount!.toCurrency(
                            companyLocale,
                            _expense!.baseCurrencyCode ??
                                ref.read(companyBaseCurrencyProvider)),
                  ),
                  if (_expense!.isForeign)
                    _SummaryTile(
                      label: l10n.expenseConvertedLabel,
                      value: _expense!.amount!.toCurrency(
                          companyLocale,
                          _expense!.baseCurrencyCode ??
                              ref.read(companyBaseCurrencyProvider)),
                    ),
                ],
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
                enabled: _isEditable && !_isSaving),
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
            enabled: enabled),
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
                expense.createdAt.toLongDate(companyLocale),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (!_isEditingEnabled && !widget.readOnly && !_isSheetApproved)
          AppButton(
            label: l10n.edit,
            variant: AppButtonVariant.normal,
            icon: Icons.edit_outlined,
            onPressed: () => setState(() => _isEditingEnabled = true),
          ),
      ],
    );
  }

  /// Approve / Decline buttons — manager only. Always right-aligned.
  Widget _buildManagerApproveDeclineRow(AppLocalizations l10n) {
    if (widget.readOnly) return const SizedBox.shrink();
    final expense = _expense;
    if (expense == null) return const SizedBox.shrink();
    // Manager line actions — the sheet is the lock, not the line: until the
    // sheet is Approved (terminal), approve/decline/delete stay available on
    // every line. A line's status is a working state, not a commitment, so an
    // accidental approve is undone with one tap (decline). Only the no-op is
    // hidden: approve on an Approved line, decline on a Declined line.
    final sheetStatusId = expense.expenseSheetStatusId;
    final isWfa = sheetStatusId == ExpenseSheetStatus.waitingForApproval.id;
    final isDeclinedSheet = sheetStatusId == ExpenseSheetStatus.declined.id;
    final statusId = expense.expenseStatusId;
    final showApprove = (isWfa || isDeclinedSheet) && statusId != 2;
    final showDecline = (isWfa || isDeclinedSheet) && statusId != 3;
    final showDelete = sheetStatusId != null &&
        SheetPermissions.canDeleteExpense(
          sheetStatusId: sheetStatusId,
          expenseStatusId: statusId,
          isManager: true,
        );
    if (!showApprove && !showDecline && !showDelete) {
      return const SizedBox.shrink();
    }

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
            if (showDelete)
              AppButton(
                label: l10n.delete,
                variant: AppButtonVariant.destructive,
                icon: Icons.delete_outline,
                onPressed: (_isSaving || _isEditingEnabled) ? null : _delete,
              ),
            if (showDelete && (showApprove || showDecline))
              const SizedBox(width: 12),
            if (showApprove)
              AppButton(
                label: l10n.approve,
                variant: AppButtonVariant.success,
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: (_isSaving || _isEditingEnabled) ? null : _approve,
              ),
            if (showApprove && showDecline) const SizedBox(width: 12),
            if (showDecline)
              AppButton(
                label: l10n.decline,
                variant: AppButtonVariant.destructive,
                icon: Icons.close,
                onPressed: (_isSaving || _isEditingEnabled) ? null : _decline,
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: l10n.discard,
            variant: AppButtonVariant.normal,
            onPressed: _isSaving ? null : _cancelManagerEdit,
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.updateExpenseDetails,
            variant: AppButtonVariant.primary,
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _isDirty && !_isSaving && _conversion.canSave ? _save : null,
          ),
        ],
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

    final saveBtn = AppButton(
      label: l10n.updateExpenseDetails,
      variant: AppButtonVariant.primary,
      icon: Icons.save_outlined,
      isLoading: _isSaving,
      onPressed: _isDirty && !_isSaving && _conversion.canSave ? _save : null,
    );
    final discardBtn = AppButton(
      label: l10n.discard,
      variant: AppButtonVariant.normal,
      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.expenseNotFound,
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.mutedForeground)),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.backToDashboard,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
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
          AppButton(
              label: l10n.continueButton,
              variant: AppButtonVariant.normal,
              onPressed: _loadExpense),
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
              AppButton(
                label: l10n.backToDashboard,
                variant: AppButtonVariant.ghost,
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
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
                ExpenseModifyImagePanel(
                  imageUrl: _expense?.imageUrl,
                  isEditable: _isEditable,
                  isManagerMode: widget.isManagerMode,
                  onReplace: () {},
                  onDownload: () {
                    final url = _expense?.imageUrl ?? '';
                    final filename = url.split('/').last.split('?').first;
                    ExcelExportService.downloadUrl(url, filename.isEmpty ? 'receipt' : filename);
                  },
                ),
                DevScanRecordButton(expenseId: _expense?.expenseId),
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
        ExpenseModifyImagePanel(
          imageUrl: _expense?.imageUrl,
          height: 192,
          isEditable: _isEditable,
          isManagerMode: widget.isManagerMode,
          onReplace: () {},
          onDownload: () {
            final url = _expense?.imageUrl ?? '';
            final filename = url.split('/').last.split('?').first;
            ExcelExportService.downloadUrl(url, filename.isEmpty ? 'receipt' : filename);
          },
        ),
        DevScanRecordButton(expenseId: _expense?.expenseId),
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

