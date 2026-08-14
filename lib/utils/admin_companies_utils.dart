import '../models/admin_companies_sort.dart';
import '../models/admin_company_row.dart';

/// Client-side search and sort over the admin companies list.
///
/// The endpoint returns every company in one payload with no query parameters,
/// so both are applied here rather than round-tripping. Nothing in this file
/// derives payment state — it only orders and filters what the server said.
class AdminCompaniesQuery {
  const AdminCompaniesQuery._();

  /// Filter by [search], then sort by [sort]. Returns a new list; [rows] is
  /// left untouched (it is the provider's cached value).
  static List<AdminCompanyRow> apply(
    List<AdminCompanyRow> rows, {
    required String search,
    required AdminCompaniesSort sort,
  }) {
    return sorted(filterByName(rows, search), sort);
  }

  /// Case-insensitive "contains" match on the company name. A blank or
  /// whitespace-only query matches everything.
  static List<AdminCompanyRow> filterByName(
    List<AdminCompanyRow> rows,
    String search,
  ) {
    final needle = search.trim().toLowerCase();
    if (needle.isEmpty) return rows;
    return rows
        .where((row) => row.companyName.toLowerCase().contains(needle))
        .toList();
  }

  static List<AdminCompanyRow> sorted(
    List<AdminCompanyRow> rows,
    AdminCompaniesSort sort,
  ) {
    final result = List<AdminCompanyRow>.of(rows);
    final direction = sort.ascending ? 1 : -1;

    result.sort((a, b) {
      final primary = _compare(a, b, sort.column) * direction;
      if (primary != 0) return primary;
      // Dart's sort is not stable, so ties would otherwise shuffle between
      // rebuilds. Newest-first is the deterministic tie-break.
      return b.creationDate.compareTo(a.creationDate);
    });

    return result;
  }

  static int _compare(
    AdminCompanyRow a,
    AdminCompanyRow b,
    AdminCompanySortColumn column,
  ) {
    switch (column) {
      case AdminCompanySortColumn.name:
        return a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase());
      case AdminCompanySortColumn.creationDate:
        return a.creationDate.compareTo(b.creationDate);
      case AdminCompanySortColumn.paymentStatus:
        // Sort on the state actually shown, not the raw server string: a
        // deactivated company reports 'PendingPayment' on the wire, so sorting
        // the raw value would file it next to unpaid signups.
        return a.displayStatus.sortRank.compareTo(b.displayStatus.sortRank);
      case AdminCompanySortColumn.userCount:
        return a.userCount.compareTo(b.userCount);
      case AdminCompanySortColumn.expenseCount:
        return a.expenseCount.compareTo(b.expenseCount);
    }
  }
}
