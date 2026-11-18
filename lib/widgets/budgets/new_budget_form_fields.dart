import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_utils.dart';
import '../../utils/expense_amount_input_formatter.dart';
import '../employee/employee_selector.dart';
import '../payments/dialog_date_field.dart';
import '../payments/dialog_text_field.dart';

/// Inline errors of the New budget form; null = no error on that field.
class NewBudgetFieldErrors {
  final String? name;
  final String? holder;
  final String? amount;
  final String? endDate;

  const NewBudgetFieldErrors({this.name, this.holder, this.amount, this.endDate});

  bool get any => name != null || holder != null || amount != null || endDate != null;
}

/// The four fields of the New budget dialog, in hand-off order: name,
/// employee (non-disabled users incl. managers, me suffixed "(me)"), initial
/// amount (LTR) and end date (up to 30 days back - FS-1013). State lives in the dialog.
class NewBudgetFormFields extends ConsumerWidget {
  const NewBudgetFormFields({
    super.key,
    required this.nameController,
    required this.amountController,
    required this.holderId,
    required this.endDate,
    required this.errors,
    required this.enabled,
    required this.onChanged,
    required this.onHolderChanged,
    required this.onEndDateChanged,
    this.currencyCode,
  });

  final TextEditingController nameController;
  final TextEditingController amountController;
  final String? holderId;
  final DateTime? endDate;
  final NewBudgetFieldErrors errors;
  final bool enabled;
  final VoidCallback onChanged;
  final ValueChanged<String?> onHolderChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  /// FS-1013: the budget's currency (edit); null = the company's (create).
  final String? currencyCode;

  /// The server's DECIMAL(18,2) guard is 999,999,999.99; the field stops there.
  static const double _maxAmount = 999999999.99;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myEmail = ref.watch(userInfoProvider)?.email.toLowerCase();
    final users = ref.watch(budgetHolderCandidatesProvider).asData?.value ?? const [];
    final names = {
      for (final u in users)
        u.userId: '${u.fullName.isEmpty ? u.email : u.fullName}'
            '${u.email.toLowerCase() == myEmail ? ' ${l10n.budgetsMe}' : ''}',
    };
    final today = budgetToday();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogTextField(
          label: l10n.budgetsColName,
          controller: nameController,
          enabled: enabled,
          maxLength: 100,
          errorText: errors.name,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) => EmployeeSelector(
            employees: names,
            selectedIds: holderId == null ? const {} : {holderId!},
            onChanged: (ids) => onHolderChanged(ids.isEmpty ? null : ids.first),
            singleSelect: true,
            sectionLabel: l10n.budgetsColEmployee,
            placeholder: '',
            formLabel: true,
            width: c.maxWidth,
            enabled: enabled,
          ),
        ),
        if (errors.holder != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
            child: Text(
              errors.holder!,
              style: const TextStyle(fontSize: 12, color: AppTheme.destructive),
            ),
          ),
        const SizedBox(height: 14),
        DialogTextField(
          label: l10n.budgetsFieldAmount,
          controller: amountController,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ExpenseAmountInputFormatter(maxAmount: _maxAmount)],
          textDirection: TextDirection.ltr,
          prefixText: NumberFormat.simpleCurrency(
            locale: 'en',
            name: currencyCode ?? ref.watch(companyBaseCurrencyProvider),
          ).currencySymbol,
          // The digits read LTR but sit where the other fields start (right
          // in Hebrew) - FS-1013 QA.
          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.end : TextAlign.start,
          errorText: errors.amount,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        DialogDateField(
          label: l10n.budgetsColEndDate,
          value: endDate,
          firstDate: budgetEarliestEndDate(today),
          lastDate: DateTime(today.year + 5, 12, 31),
          enabled: enabled,
          errorText: errors.endDate,
          onChanged: onEndDateChanged,
        ),
      ],
    );
  }
}
