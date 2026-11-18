import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../services/budget_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/adaptive_dialog_utils.dart';
import '../../utils/budget_copy_utils.dart';
import '../../utils/budget_utils.dart';
import '../app_button.dart';
import '../error_alert.dart';
import 'budget_negative_confirm.dart';
import 'new_budget_form_fields.dart';

/// B3 - New budget (UX hand-off section 2.3). Dialog on desktop, bottom sheet
/// on mobile ([showAdaptiveSheetDialog]). Returns the created budget, or null
/// on cancel. Errors show under each field after the first Create; amount and
/// date errors also show live once a value is typed.
/// FS-1013 PC-2: with a [budget] it is "Edit budget" (prefilled, "Save"); a past
/// end date errs only once changed; below-zero amounts: [confirmBudgetBelowZero].
class NewBudgetDialog extends ConsumerStatefulWidget {
  const NewBudgetDialog({super.key, this.budget});
  final Budget? budget; // null = create

  static Future<Budget?> show(BuildContext context) =>
      showAdaptiveSheetDialog<Budget>(context, builder: (_) => const NewBudgetDialog());

  static Future<Budget?> showEdit(BuildContext context, Budget budget) =>
      showAdaptiveSheetDialog<Budget>(context, builder: (_) => NewBudgetDialog(budget: budget));

  @override
  ConsumerState<NewBudgetDialog> createState() => _NewBudgetDialogState();
}

class _NewBudgetDialogState extends ConsumerState<NewBudgetDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String? _holderId;
  DateTime? _endDate;
  bool _attempted = false;
  bool _saving = false;
  String? _serverError;

  bool get _editing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    if (b == null) return;
    _name.text = b.name;
    _amount.text = budgetAmountInput(b.initialAmount);
    _holderId = b.holderUserId;
    _endDate = b.endDate;
  }

  /// An overdue budget keeps its end date through an edit of anything else.
  bool get _endDateChanged => !DateUtils.isSameDay(_endDate, widget.budget?.endDate);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? get _amountValue => double.tryParse(_amount.text.replaceAll(',', ''));

  NewBudgetFieldErrors _errors(AppLocalizations l10n) {
    final today = budgetToday();
    final amountTyped = _amount.text.isNotEmpty;
    final amount = _amountValue;
    return NewBudgetFieldErrors(
      name: _attempted && _name.text.trim().isEmpty ? l10n.budgetsErrRequired : null,
      holder: _attempted && _holderId == null ? l10n.budgetsErrRequired : null,
      amount: !amountTyped
          ? (_attempted ? l10n.budgetsErrRequired : null)
          : (amount == null || amount <= 0 ? l10n.budgetsErrAmount : null),
      endDate: _endDate == null
          ? (_attempted ? l10n.budgetsErrRequired : null)
          : (_endDateChanged && _endDate!.isBefore(budgetEarliestEndDate(today)) ? l10n.budgetsErrDate : null),
    );
  }

  Future<void> _create(AppLocalizations l10n) async {
    setState(() {
      _attempted = true;
      _serverError = null;
    });
    if (_errors(l10n).any) return;
    final b = widget.budget;
    // An edit with nothing changed closes without a call or a toast.
    if (b != null && !budgetEditChanges(b, _name.text.trim(), _holderId!, _amountValue!, _endDate!)) {
      return Navigator.of(context).pop();
    }
    if (b != null && (!await confirmBudgetBelowZero(context, ref, b, _amountValue!) || !mounted)) return;

    setState(() => _saving = true);
    try {
      final service = ref.read(budgetServiceProvider);
      final budget = _editing
          ? await service.update(
              widget.budget!.budgetId,
              name: _name.text.trim(),
              holderUserId: _holderId!,
              initialAmount: _amountValue!,
              endDate: _endDate!,
            )
          : await service.create(
              name: _name.text.trim(),
              holderUserId: _holderId!,
              initialAmount: _amountValue!,
              endDate: _endDate!,
            );
      if (mounted) Navigator.of(context).pop(budget);
    } on BudgetException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = budgetErrorText(l10n, e.errorCode) ?? l10n.genericErrorRetry;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = l10n.genericErrorRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // No dismiss (barrier, back, drag) while the create is in flight - the
    // caller would lose the created budget and never refresh.
    return PopScope(
      canPop: !_saving,
      child: Padding(
      padding: EdgeInsetsDirectional.only(
        start: 20,
        end: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? l10n.budgetsEditTitle : l10n.budgetsNew,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 16),
            if (_serverError != null) ...[
              ErrorAlert(message: _serverError!),
              const SizedBox(height: 12),
            ],
            NewBudgetFormFields(
              nameController: _name,
              amountController: _amount,
              holderId: _holderId,
              endDate: _endDate,
              errors: _errors(l10n),
              enabled: !_saving,
              onChanged: () => setState(() {}),
              onHolderChanged: (id) => setState(() => _holderId = id),
              onEndDateChanged: (d) => setState(() => _endDate = d),
              currencyCode: widget.budget?.currencyCode,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: l10n.cancel,
                  variant: AppButtonVariant.normal,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: _editing ? l10n.budgetsSave : l10n.budgetsCreate,
                  isLoading: _saving,
                  onPressed: () => _create(l10n),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
