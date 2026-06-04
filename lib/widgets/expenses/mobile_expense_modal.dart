import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../ai_badge.dart';
import '../app_button.dart';
import '../../models/expense_detail.dart';
import '../../models/expense_summary.dart';
import '../../models/expense_category.dart';
import '../../models/expense_currency.dart';
import '../../models/update_expense_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/expense_amount_input_formatter.dart';

/// Shows a bottom-sheet drawer for viewing/editing a pending expense on mobile.
///
/// Only opened for pending expenses. Non-pending expenses navigate to
/// [EmployeeExpenseDetailScreen] instead.
Future<void> showMobileExpenseModal(
  BuildContext context,
  ExpenseSummary expense,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MobileExpenseModal(expense: expense),
  );
}

class _MobileExpenseModal extends ConsumerStatefulWidget {
  final ExpenseSummary expense;

  const _MobileExpenseModal({required this.expense});

  @override
  ConsumerState<_MobileExpenseModal> createState() =>
      _MobileExpenseModalState();
}

class _MobileExpenseModalState extends ConsumerState<_MobileExpenseModal> {
  ExpenseDetail? _detail;
  bool _isLoading = true;
  String? _loadError;

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

  bool get _canSave =>
      _amountController.text.trim().isNotEmpty &&
      _selectedCategoryId != null &&
      _merchantController.text.trim().isNotEmpty &&
      _selectedDate != null;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _merchantController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _receiptRefController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final service = ref.read(expenseServiceProvider);
      final detail = await service.getExpenseById(widget.expense.expenseId);
      if (!mounted) return;
      _amountController.text = detail.amount != null
          ? detail.amount!.toStringAsFixed(detail.amount! % 1 == 0 ? 0 : 2)
          : '';
      _merchantController.text = detail.merchantName ?? '';
      _noteController.text = detail.note ?? '';
      _receiptRefController.text = detail.receiptRef ?? '';
      _selectedDate = detail.expenseDate;
      _selectedCategoryId = detail.categoryId;
      _selectedCurrencyCode = detail.currencyCode ?? 'ILS';
      _isAiData = detail.isAiData;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving || _detail == null) return;
    setState(() { _isSaving = true; _saveError = null; });

    // Capture context-dependent values before any await.
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.updateExpense(
        widget.expense.expenseId,
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
          _saveError = l10n.expenseClosedError;
        });
      }
    } on ExpenseNotFoundException {
      if (mounted) {
        setState(() { _isSaving = false; });
        navigator.pop();
      }
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
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
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  // ── Build helpers ────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
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
    bool monospace = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String companyLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: _isSaving ? null : _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate?.toCompanyDate(companyLocale) ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppTheme.mutedForeground),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n, Locale uiLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.categoryLabel),
        DropdownMenu<int>(
          initialSelection: _selectedCategoryId,
          enabled: !_isSaving,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.selectCategory,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          dropdownMenuEntries: ExpenseCategory.orderedValues
              .map((cat) => DropdownMenuEntry<int>(
                    value: cat.id,
                    label: cat.labelForLocale(uiLocale),
                  ))
              .toList(),
          onSelected: _isSaving
              ? null
              : (value) => setState(() => _selectedCategoryId = value),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.currencyLabel),
        DropdownMenu<String>(
          initialSelection: _selectedCurrencyCode,
          enabled: !_isSaving,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.currencyPlaceholder,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          dropdownMenuEntries: ExpenseCurrency.values
              .map((c) =>
                  DropdownMenuEntry<String>(value: c.code, label: c.displayLabel))
              .toList(),
          onSelected: _isSaving
              ? null
              : (value) => setState(() => _selectedCurrencyCode = value),
        ),
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
                if (_detail!.amount != null)
                  _SummaryTile(
                    label: l10n.amountLabel,
                    value: _detail!.amount!.toCurrency(
                        companyLocale, _detail!.currencyCode ?? 'ILS'),
                  ),
                _SummaryTile(
                    label: l10n.expenseDate,
                    value: _detail!.expenseDate.toCompanyDate(companyLocale)),
                if (_detail!.merchantName != null)
                  _SummaryTile(
                      label: l10n.merchantLabel,
                      value: _detail!.merchantName!),
                if (_detail!.receiptRef != null)
                  _SummaryTile(
                      label: l10n.receiptRefLabel,
                      value: _detail!.receiptRef!),
              ],
            ),
          ] else ...[
            Column(
              children: [
                _buildTextField(
                  l10n.amountLabel,
                  _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ExpenseAmountInputFormatter()],
                ),
                const SizedBox(height: 12),
                _buildCurrencyDropdown(l10n),
                const SizedBox(height: 12),
                _buildDateField(l10n.expenseDate, companyLocale),
                const SizedBox(height: 12),
                _buildTextField(l10n.merchantLabel, _merchantController),
                const SizedBox(height: 12),
                _buildTextField(l10n.receiptRefLabel, _receiptRefController,
                    monospace: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptSection(String companyLocale) {
    final imageUrl = _detail?.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 128,
        decoration: BoxDecoration(
          color: AppTheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 32, color: AppTheme.mutedForeground),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 192,
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
            errorBuilder: (context2, err, stack) => const Center(
              child: Icon(Icons.broken_image,
                  size: 40, color: AppTheme.mutedForeground),
            ),
          ),
          PositionedDirectional(
            top: 8,
            end: 8,
            child: GestureDetector(
              onTap: () => _showExpandDialog(imageUrl),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.card.withAlpha(204),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.open_in_full,
                    size: 16, color: AppTheme.foreground),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.98,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    final uiLocale = Localizations.localeOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Center(
                child: Container(
                  width: 100,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.expenseDetail,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Text(_loadError!,
                              style: const TextStyle(
                                  color: AppTheme.destructive)))
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            _buildReceiptSection(companyLocale),
                            const SizedBox(height: 16),
                            if (_isAiData) ...[
                              _buildCategoryDropdown(l10n, uiLocale),
                              const SizedBox(height: 16),
                              _buildTextField(l10n.noteLabel, _noteController,
                                  maxLines: 2),
                              const SizedBox(height: 16),
                              _buildAiDetectedPanel(
                                  l10n, companyLocale, uiLocale),
                            ] else ...[
                              _buildTextField(
                                  l10n.receiptRefLabel, _receiptRefController,
                                  monospace: true),
                              const SizedBox(height: 12),
                              _buildTextField(
                                l10n.amountLabel,
                                _amountController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  ExpenseAmountInputFormatter()
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildCurrencyDropdown(l10n),
                              const SizedBox(height: 12),
                              _buildDateField(
                                  l10n.expenseDate, companyLocale),
                              const SizedBox(height: 12),
                              _buildTextField(
                                  l10n.merchantLabel, _merchantController),
                              const SizedBox(height: 12),
                              _buildCategoryDropdown(l10n, uiLocale),
                              const SizedBox(height: 12),
                              _buildTextField(l10n.noteLabel, _noteController,
                                  maxLines: 3),
                            ],
                            const SizedBox(height: 16),
                            if (_saveError != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 16, color: AppTheme.destructive),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(_saveError!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.destructive)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: l10n.updateExpenseDetails,
                                variant: AppButtonVariant.primary,
                                icon: Icons.save_outlined,
                                isLoading: _isSaving,
                                onPressed:
                                    _canSave && !_isSaving ? _save : null,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

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
