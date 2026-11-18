import 'payment_report_row.dart';

/// Paging envelope for `GET /api/payments` — same shape as the sheet lists.
///
/// PC-8: To pay and To collect totals are kept apart, never netted.
class PagedPayments {
  final List<PaymentReportRow> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final double pageTotalAmount;
  final double grandTotalAmount;
  final int payCount;
  final int collectCount;
  final double pageCollectAmount;
  final double grandCollectAmount;

  const PagedPayments({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.pageTotalAmount,
    required this.grandTotalAmount,
    this.payCount = 0,
    this.collectCount = 0,
    this.pageCollectAmount = 0,
    this.grandCollectAmount = 0,
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

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

  factory PagedPayments.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    final totalCount = (json['totalCount'] as num?)?.toInt() ?? 0;
    final collectCount = (json['collectCount'] as num?)?.toInt() ?? 0;
    return PagedPayments(
      items: itemsJson
          .map((e) => PaymentReportRow.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: totalCount,
      hasMore: json['hasMore'] as bool? ?? false,
      pageTotalAmount: _d(json['pageTotalAmount']),
      grandTotalAmount: _d(json['grandTotalAmount']),
      // Pre-PC-8 payloads: every row is a Pay row.
      payCount:
          (json['payCount'] as num?)?.toInt() ?? totalCount - collectCount,
      collectCount: collectCount,
      pageCollectAmount: _d(json['pageCollectAmount']),
      grandCollectAmount: _d(json['grandCollectAmount']),
    );
  }

  /// Drops just-processed sheets from the page, keeping the manager's place.
  PagedPayments withoutSheets(Set<String> sheetIds) {
    final removed = items
        .where((r) => sheetIds.contains(r.expenseSheetId))
        .toList(growable: false);
    if (removed.isEmpty) return this;
    final pays = removed.where((r) => !r.isCollect);
    final collects = removed.where((r) => r.isCollect);
    final payAmount = pays.fold<double>(0, (s, r) => s + r.magnitude);
    final collectAmount = collects.fold<double>(0, (s, r) => s + r.magnitude);
    return PagedPayments(
      items: items
          .where((r) => !sheetIds.contains(r.expenseSheetId))
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      totalCount: totalCount - removed.length,
      hasMore: hasMore,
      pageTotalAmount: pageTotalAmount - payAmount,
      grandTotalAmount: grandTotalAmount - payAmount,
      payCount: payCount - pays.length,
      collectCount: collectCount - collects.length,
      pageCollectAmount: pageCollectAmount - collectAmount,
      grandCollectAmount: grandCollectAmount - collectAmount,
    );
  }
}
