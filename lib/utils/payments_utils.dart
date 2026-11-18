import '../models/payment_report_row.dart';

/// Sortable columns of the Payments Report (D15 — the API has no sort param,
/// so sorting is client-side over the loaded page).
enum PaymentsSortField {
  employee,
  govId,
  cycle,
  approvedDate,
  amount,
  sheetType,
  processedDate,
}

/// FS-1020 PC-8: totals never net — To pay and To collect are counted and
/// summed apart (amounts as positive magnitudes).
class PaymentTotals {
  final int payCount;
  final double payAmount;
  final int collectCount;
  final double collectAmount;

  const PaymentTotals({
    this.payCount = 0,
    this.payAmount = 0,
    this.collectCount = 0,
    this.collectAmount = 0,
  });

  int get count => payCount + collectCount;
  bool get hasCollect => collectCount > 0;

  /// The company takes back more than it pays.
  bool get isNetNegative => ((payAmount - collectAmount) * 100).round() < 0;

  static PaymentTotals of(Iterable<PaymentReportRow> rows) {
    var payCount = 0, collectCount = 0;
    var payAmount = 0.0, collectAmount = 0.0;
    for (final r in rows) {
      if (r.isCollect) {
        collectCount++;
        collectAmount += r.magnitude;
      } else {
        payCount++;
        payAmount += r.magnitude;
      }
    }
    return PaymentTotals(
      payCount: payCount,
      payAmount: payAmount,
      collectCount: collectCount,
      collectAmount: collectAmount,
    );
  }
}

/// Pure selection helpers for the Payments Report.
class PaymentsSelectionUtils {
  /// Split totals of the selected rows (bulk bar / dialog summary).
  static PaymentTotals totalsFor(
          List<PaymentReportRow> rows, Set<String> selectedIds) =>
      PaymentTotals.of(
          rows.where((r) => selectedIds.contains(r.expenseSheetId)));
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
      case PaymentsSortField.cycle:
        return a.cycleLabel
            .toLowerCase()
            .compareTo(b.cycleLabel.toLowerCase());
      case PaymentsSortField.approvedDate:
        return _compareDates(a.approvedDate, b.approvedDate);
      case PaymentsSortField.amount:
        return a.amount.compareTo(b.amount);
      case PaymentsSortField.sheetType:
        // Monthly before Budget; budgets by name, then number.
        final byType = a.sheetType.index.compareTo(b.sheetType.index);
        if (byType != 0) return byType;
        final byName = (a.budgetName ?? '').toLowerCase()
            .compareTo((b.budgetName ?? '').toLowerCase());
        if (byName != 0) return byName;
        return (a.budgetNumber ?? 0).compareTo(b.budgetNumber ?? 0);
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
