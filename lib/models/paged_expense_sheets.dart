import 'expense_sheet_list_item.dart';

/// Paging envelope returned by every paged sheet-list endpoint:
///   - `GET /api/expense-sheets/queue` (cap 12, no client paging)
///   - `GET /api/expense-sheets?statusId=...&page=...&pageSize=...`
///
/// `pageTotalAmount` = sum across items on this page.
/// `grandTotalAmount` = sum across the FULL filtered set (every row matching
/// the same filters, not capped by paging or by the /queue TOP 12).
/// `hasMore` is strictly `(page * pageSize) < totalCount`.
class PagedExpenseSheets {
  final List<ExpenseSheetListItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final double pageTotalAmount;
  final double grandTotalAmount;

  const PagedExpenseSheets({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.pageTotalAmount,
    required this.grandTotalAmount,
  });

  /// Empty envelope used as the loading / error / unauthenticated fallback.
  static const empty = PagedExpenseSheets(
    items: <ExpenseSheetListItem>[],
    page: 1,
    pageSize: 0,
    totalCount: 0,
    hasMore: false,
    pageTotalAmount: 0,
    grandTotalAmount: 0,
  );

  factory PagedExpenseSheets.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return PagedExpenseSheets(
      items: itemsJson
          .map((e) =>
              ExpenseSheetListItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      pageTotalAmount: (json['pageTotalAmount'] as num?)?.toDouble() ?? 0,
      grandTotalAmount: (json['grandTotalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
