import 'payment_report_row.dart';

/// Paging envelope for `GET /api/payments` — same shape as the sheet lists.
///
/// `pageTotalAmount` = sum across items on this page.
/// `grandTotalAmount` = sum across the FULL filtered set.
class PagedPayments {
  final List<PaymentReportRow> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final double pageTotalAmount;
  final double grandTotalAmount;

  const PagedPayments({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.pageTotalAmount,
    required this.grandTotalAmount,
  });

  /// Empty envelope used as the loading / error / unauthenticated fallback.
  static const empty = PagedPayments(
    items: <PaymentReportRow>[],
    page: 1,
    pageSize: 0,
    totalCount: 0,
    hasMore: false,
    pageTotalAmount: 0,
    grandTotalAmount: 0,
  );

  factory PagedPayments.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return PagedPayments(
      items: itemsJson
          .map((e) => PaymentReportRow.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      pageTotalAmount: (json['pageTotalAmount'] as num?)?.toDouble() ?? 0,
      grandTotalAmount: (json['grandTotalAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Drops [sheetIds] from the page in place (after a successful process under
  /// the Awaiting filter) so the manager keeps scroll/filter context without a
  /// refetch. Totals are adjusted by the removed rows' amounts.
  PagedPayments withoutSheets(Set<String> sheetIds) {
    final removed = items
        .where((r) => sheetIds.contains(r.expenseSheetId))
        .toList(growable: false);
    if (removed.isEmpty) return this;
    final removedAmount =
        removed.fold<double>(0, (sum, r) => sum + r.amount);
    final removedCount = removed.length;
    return PagedPayments(
      items: items
          .where((r) => !sheetIds.contains(r.expenseSheetId))
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      totalCount: totalCount - removedCount,
      hasMore: hasMore,
      pageTotalAmount: pageTotalAmount - removedAmount,
      grandTotalAmount: grandTotalAmount - removedAmount,
    );
  }
}
