import '../models/admin_company_user_row.dart';

/// The view over the people list: which rows the impersonation picker actually
/// renders for a given company.
///
/// A pure function on domain data, kept out of the widgets (CR Rule 2) and, more
/// importantly, kept in ONE place — the screen chrome and the table both need
/// the same answer, and two copies of "is this the company I asked for?" is
/// exactly the sort of drift that puts one customer's staff on another
/// customer's page.
class AdminCompanyUsersQuery {
  const AdminCompanyUsersQuery._();

  /// Rows to render for [companyId], or empty when [users] describes a
  /// different company — which happens between opening a company and its fetch
  /// landing, because the provider is keepAlive and still holds the previous
  /// one.
  ///
  /// No sorting: the API returns managers first, then employees, each by name,
  /// and re-deriving that here would be a second definition free to drift.
  static List<AdminCompanyUserRow> apply(
    AdminCompanyUsers? users, {
    required String companyId,
    required bool showInactive,
    required String search,
  }) {
    if (!isForCompany(users, companyId)) return const [];

    return filterBySearch(
      filterByActive(users!.rows, showInactive),
      search,
    );
  }

  static List<AdminCompanyUserRow> filterByActive(
    List<AdminCompanyUserRow> rows,
    bool showInactive,
  ) {
    if (showInactive) return rows;
    return rows.where((u) => u.isActive).toList();
  }

  /// Case-insensitive "contains" over BOTH name and email. An agent on a call
  /// has whichever the caller happened to give them, so matching only one would
  /// make the box useless half the time. A blank query matches everything.
  static List<AdminCompanyUserRow> filterBySearch(
    List<AdminCompanyUserRow> rows,
    String search,
  ) {
    final needle = search.trim().toLowerCase();
    if (needle.isEmpty) return rows;

    return rows.where((u) {
      final name = u.fullName?.toLowerCase() ?? '';
      return name.contains(needle) || u.email.toLowerCase().contains(needle);
    }).toList();
  }

  /// Whether [users] is the answer for [companyId]. A false here must read as
  /// "still loading", never as "this company has nobody".
  static bool isForCompany(AdminCompanyUsers? users, String companyId) {
    return users != null && users.companyId == companyId;
  }
}
