import '../generated/l10n/app_localizations.dart';
import '../models/budget.dart';
import '../models/expense_cycle.dart';
import '../models/payment_direction.dart';
import 'format_utils.dart';

/// FS-1020 PC-8 settlement rules on the client (budgets-guide D10 / D11).

/// Spent - budget amount, from the holder's side: > 0 the company pays the
/// holder (overspent), < 0 it collects from them (unspent), 0 nothing.
/// Spent already excludes declined lines (the server's balance rule).
double budgetSettlementAmount(Budget b) => b.spentAmount - b.budgetAmount;

/// The cycle a settlement lands in: the company's Open cycle, as `yyyy/MM`.
/// Null when none is loaded / open.
String? openCycleLabel(List<ExpenseCycle> cycles) {
  for (final c in cycles) {
    if (!c.isOpen) continue;
    final label = c.cycleLabel;
    if (label != null && label.isNotEmpty) return label;
    final start = DateTime.tryParse(c.cycleStartAt);
    if (start == null) continue;
    return '${start.year}/${start.month.toString().padLeft(2, '0')}';
  }
  return null;
}

/// What approving does and where:
/// "To collect ₪200 from Dana - in the payments of November 2026",
/// "To pay ₪50 to Dana - ...", or "Nothing to settle ...". The cycle part is
/// dropped when [cycleLabel] is null.
String budgetSettlementText(
  AppLocalizations l10n, {
  required double settlement,
  required String holder,
  required String? cycleLabel,
  required String locale,
  required String currencyCode,
}) {
  final direction = PaymentDirection.fromAmount(settlement);
  if (direction == null) return l10n.settlementNothing;
  final amount = settlement.abs().toCurrency(locale, currencyCode);
  // First-strong isolate: a Latin name keeps its place inside a Hebrew line.
  final name = '\u2068$holder\u2069';
  final head = direction == PaymentDirection.pay
      ? '${l10n.paymentsDirectionToPay} $amount ${l10n.settlementPayTo} $name'
      : '${l10n.paymentsDirectionToCollect} $amount ${l10n.settlementCollectFrom} $name';
  if (cycleLabel == null) return head;
  return '$head - ${l10n.settlementInPaymentsOf} '
      '${cycleLabel.toCycleLongMonth(locale)}';
}

/// [budgetSettlementText] for approving [b] now.
String budgetApprovalSettlementText(
  AppLocalizations l10n,
  Budget b, {
  required String? cycleLabel,
  required String locale,
}) =>
    budgetSettlementText(
      l10n,
      settlement: budgetSettlementAmount(b),
      holder: b.holderDisplayName,
      cycleLabel: cycleLabel,
      locale: locale,
      currencyCode: b.currencyCode,
    );
