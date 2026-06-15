import '../models/payment_report_row.dart';
import 'format_utils.dart';

/// Sortable columns of the Payments Report (D15 — the API has no sort param,
/// so sorting is client-side over the loaded page).
enum PaymentsSortField {
  employee,
  govId,
  email,
  cycle,
  approvedDate,
  amount,
  paymentStatus,
  processedDate,
}

/// Pure selection helpers for the Payments Report.
class PaymentsSelectionUtils {
  /// Combined payable amount of the selected rows (bulk bar summary).
  static double _totalAmountFor(
      List<PaymentReportRow> rows, Set<String> selectedIds) {
    return rows
        .where((r) => selectedIds.contains(r.expenseSheetId))
        .fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// [_totalAmountFor], formatted in the company locale/currency for display.
  static String totalAmountTextFor(
    List<PaymentReportRow> rows,
    Set<String> selectedIds, {
    required String locale,
    required String? currencyCode,
  }) {
    final total = _totalAmountFor(rows, selectedIds);
    return _formatAmount(total, locale, currencyCode);
  }

  /// Combined payable amount of ALL [rows], formatted — for the results
  /// "sheets found (count · total)" caption.
  static String allAmountText(
    List<PaymentReportRow> rows, {
    required String locale,
    required String? currencyCode,
  }) {
    final total = rows.fold<double>(0, (sum, r) => sum + r.amount);
    return _formatAmount(total, locale, currencyCode);
  }

  static String _formatAmount(double total, String locale, String? currency) {
    return currency != null
        ? total.toCurrency(locale, currency)
        : total.toFormattedNumber(locale);
  }
}

/// Pure sorting helpers for the Payments Report.
class PaymentsSortUtils {
  /// Returns a new list sorted by [field]. Null dates sort last regardless of
  /// direction; text compares case-insensitively. [field] null returns the
  /// server order untouched.
  static List<PaymentReportRow> sort(
    List<PaymentReportRow> rows,
    PaymentsSortField? field, {
    required bool ascending,
  }) {
    if (field == null) return rows;
    final sorted = List<PaymentReportRow>.of(rows);
    sorted.sort((a, b) {
      // Null dates always sink to the bottom, in BOTH directions — decided
      // before the ascending flip so descending can't lift them to the top.
      final nullCmp = _nullLastFor(a, b, field);
      if (nullCmp != null) return nullCmp;
      final cmp = _compare(a, b, field);
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  /// For the nullable date columns, returns a direction-independent ordering
  /// when exactly one side is null (non-null first). Null otherwise (let the
  /// normal comparison + direction apply).
  static int? _nullLastFor(
      PaymentReportRow a, PaymentReportRow b, PaymentsSortField field) {
    final (da, db) = switch (field) {
      PaymentsSortField.approvedDate => (a.approvedDate, b.approvedDate),
      PaymentsSortField.processedDate => (a.processedDate, b.processedDate),
      _ => (null, null),
    };
    if (field != PaymentsSortField.approvedDate &&
        field != PaymentsSortField.processedDate) {
      return null;
    }
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return null;
  }

  static int _compare(
      PaymentReportRow a, PaymentReportRow b, PaymentsSortField field) {
    switch (field) {
      case PaymentsSortField.employee:
        return a.employeeName
            .toLowerCase()
            .compareTo(b.employeeName.toLowerCase());
      case PaymentsSortField.govId:
        return (a.employeeGovId ?? '').compareTo(b.employeeGovId ?? '');
      case PaymentsSortField.email:
        return (a.employeeEmail ?? '')
            .toLowerCase()
            .compareTo((b.employeeEmail ?? '').toLowerCase());
      case PaymentsSortField.cycle:
        return a.cycleLabel
            .toLowerCase()
            .compareTo(b.cycleLabel.toLowerCase());
      case PaymentsSortField.approvedDate:
        return _compareDates(a.approvedDate, b.approvedDate);
      case PaymentsSortField.amount:
        return a.amount.compareTo(b.amount);
      case PaymentsSortField.paymentStatus:
        return (a.paymentStatus?.wireName ?? '')
            .compareTo(b.paymentStatus?.wireName ?? '');
      case PaymentsSortField.processedDate:
        return _compareDates(a.processedDate, b.processedDate);
    }
  }

  /// Nulls always sort last (independent of direction the caller applies, a
  /// null date is "no data" — never the top of either ordering).
  static int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
