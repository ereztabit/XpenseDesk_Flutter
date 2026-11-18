import '../generated/l10n/app_localizations.dart';
import '../models/company_module.dart';
import '../models/payment_direction.dart';
import '../models/payment_report_row.dart';
import '../models/payment_status.dart';
import 'format_utils.dart';
import 'payments_utils.dart';

/// Payments Report captions (PC-8: any sheet type, pay / collect).

String paymentAmountText(double amount, String locale, String? currencyCode) =>
    currencyCode != null
    ? amount.toCurrency(locale, currencyCode)
    : amount.toFormattedNumber(locale);

/// Money the company charges: "-₪60.00", kept left-to-right so the minus
/// never jumps in Hebrew.
String paymentChargeText(
  double magnitude,
  String locale,
  String? currencyCode,
) => '\u2066-${paymentAmountText(magnitude, locale, currencyCode)}\u2069';

/// A payments row amount - negative when the company charges.
String paymentRowAmountText(
  PaymentReportRow row,
  String locale,
  String? currencyCode,
) => row.isCollect
    ? paymentChargeText(row.magnitude, locale, currencyCode)
    : paymentAmountText(row.magnitude, locale, currencyCode);

/// Net of a set of rows: "₪467.24", or "-₪60.00" when the company takes
/// money back - no plus sign (owner, 2026-11-18).
String paymentNetText(PaymentTotals t, String locale, String? currencyCode) {
  final net = ((t.payAmount - t.collectAmount) * 100).round() / 100;
  final text = paymentAmountText(net.abs(), locale, currencyCode);
  return net < 0 ? paymentChargeText(net.abs(), locale, currencyCode) : text;
}

/// Total row label under the Payments list: "Total · 4 sheets" (owner,
/// 2026-11-18 - replaces the "sheets found" caption).
String paymentsTotalLabelText(AppLocalizations l10n, int count) =>
    '${l10n.paymentsTotalLabel} · $count '
    '${count == 1 ? l10n.awaitingPaymentSheetSingular : l10n.awaitingPaymentSheetPlural}';

/// Bulk action label: "Process 2 sheets" / "Process 1 sheet".
String paymentProcessCountText(AppLocalizations l10n, int count) =>
    '${l10n.paymentProcessButton} $count '
    '${count == 1 ? l10n.awaitingPaymentSheetSingular : l10n.awaitingPaymentSheetPlural}';

String paymentDirectionText(AppLocalizations l10n, PaymentDirection d) =>
    d == PaymentDirection.collect
    ? l10n.paymentsDirectionToCollect
    : l10n.paymentsDirectionToPay;

/// Awaiting Payment / Paid / Collected; plain "Processed" without a direction.
String paymentStatusText(
  AppLocalizations l10n,
  PaymentStatus status, {
  PaymentDirection? direction,
}) {
  if (status == PaymentStatus.awaitingPayment) return l10n.paymentStatusPending;
  return switch (direction) {
    PaymentDirection.pay => l10n.paymentStatusPaid,
    PaymentDirection.collect => l10n.paymentStatusCollected,
    null => l10n.paymentStatusProcessed,
  };
}

String paymentSheetTypeText(AppLocalizations l10n, CompanyModuleKey type) =>
    type == CompanyModuleKey.pettyCash
    ? l10n.paymentsSheetTypeBudget
    : l10n.paymentsSheetTypeMonthly;

/// "Events #1004" for a budget row; null for a Monthly row.
String? paymentBudgetText(PaymentReportRow row) {
  if (row.sheetType != CompanyModuleKey.pettyCash) return null;
  final name = row.budgetName?.trim() ?? '';
  final number = row.budgetNumber != null ? '#${row.budgetNumber}' : '';
  final text = [name, number].where((s) => s.isNotEmpty).join(' ');
  return text.isEmpty ? null : text;
}

/// Bulk-bar line: "3 sheets of ₪X" as today, or "3 sheets · -₪X" (net)
/// when the selection holds money to charge.
String paymentSelectionText(
  AppLocalizations l10n,
  PaymentTotals t, {
  required String locale,
  required String? currencyCode,
}) {
  final sheets = t.count == 1
      ? l10n.awaitingPaymentSheetSingular
      : l10n.awaitingPaymentSheetPlural;
  return t.hasCollect
      ? '${t.count} $sheets · ${paymentNetText(t, locale, currencyCode)}'
      : '${t.count} $sheets ${l10n.bulkSelectionOf} '
            '${paymentAmountText(t.payAmount, locale, currencyCode)}';
}
