import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_log_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../ltr_text.dart';

/// FS-1013 PC-2: the caption of a budget audit event on the Activity card.
String budgetLogEventLabel(BudgetLogEvent event, AppLocalizations l10n) => switch (event) {
  BudgetLogEvent.renamed => l10n.budgetsEvRenamed,
  BudgetLogEvent.holderChanged => l10n.budgetsEvHolder,
  BudgetLogEvent.endDateChanged => l10n.budgetsEvEndDate,
  BudgetLogEvent.amountChanged => l10n.budgetsEvAmount,
  BudgetLogEvent.lineApproved => l10n.budgetsEvLineApproved,
  BudgetLogEvent.lineDeclined => l10n.budgetsEvLineDeclined,
  BudgetLogEvent.deleted => l10n.budgetsDeleted,
};

/// FS-1013 PC-2: the detail line under a budget audit event - "old -> new"
/// for a field change, "merchant  amount" for a line decision. Every value is
/// its own run (a Hebrew merchant next to an LTR amount, an English name on a
/// Hebrew screen never scramble); dates and amounts in the company's format,
/// an email (a holder without a name) LTR. Renders nothing when the server
/// sent no value.
class BudgetLogEventDetail extends StatelessWidget {
  const BudgetLogEventDetail({
    super.key,
    required this.event,
    required this.entry,
    required this.companyLocale,
    required this.currencyCode,
  });

  final BudgetLogEvent event;
  final ExpenseSheetLogEntry entry;
  final String companyLocale;
  final String currencyCode;

  static const _style = TextStyle(fontSize: 12, color: AppTheme.foreground);

  bool get _isLine => event == BudgetLogEvent.lineApproved || event == BudgetLogEvent.lineDeclined;

  String? _value(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    switch (event) {
      case BudgetLogEvent.endDateChanged:
        final d = DateTime.tryParse(raw);
        return d == null ? raw : DateTime(d.year, d.month, d.day).toCompanyDate(companyLocale);
      case BudgetLogEvent.amountChanged:
      case BudgetLogEvent.lineApproved:
      case BudgetLogEvent.lineDeclined:
        final a = double.tryParse(raw);
        return a == null ? raw : a.toCurrency(companyLocale, currencyCode);
      default:
        return raw.trim();
    }
  }

  Widget _run(String text, {bool ltr = false}) =>
      ltr || text.contains('@') ? LtrText(text, style: _style) : Text(text, style: _style);

  @override
  Widget build(BuildContext context) {
    final amountLike = event == BudgetLogEvent.amountChanged ||
        event == BudgetLogEvent.endDateChanged ||
        _isLine;
    final List<Widget> runs;
    if (_isLine) {
      final merchant = _value(entry.oldValue);
      final amount = _value(entry.newValue);
      runs = [
        if (merchant != null) Text(merchant, style: _style),
        if (amount != null) _run(amount, ltr: true),
      ];
    } else {
      final from = _value(entry.oldValue);
      final to = _value(entry.newValue);
      if (from == null && to == null) return const SizedBox.shrink();
      runs = [
        if (from != null) _run(from, ltr: amountLike),
        // Mirrors in RTL, so it always points the reading way.
        Icon(Icons.arrow_forward, size: 12, color: _style.color),
        if (to != null) _run(to, ltr: amountLike),
      ];
    }
    if (runs.isEmpty) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: runs,
    );
  }
}
