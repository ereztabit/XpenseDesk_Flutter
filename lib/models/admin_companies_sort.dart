import 'admin_company_row.dart';

/// A sortable column of the admin companies table.
enum AdminCompanySortColumn {
  name,
  creationDate,
  paymentStatus,
  userCount,
  expenseCount;

  /// Whether a *first* tap on this column should sort ascending.
  ///
  /// Text reads naturally A→Z, but for a date or a count the interesting end is
  /// the big one — newest companies, busiest tenants — so those open descending.
  bool get defaultAscending => switch (this) {
        AdminCompanySortColumn.name => true,
        AdminCompanySortColumn.paymentStatus => true,
        AdminCompanySortColumn.creationDate => false,
        AdminCompanySortColumn.userCount => false,
        AdminCompanySortColumn.expenseCount => false,
      };
}

/// Where a status sorts, independent of how [AdminCompanyDisplayStatus] happens
/// to be declared. Ascending runs healthiest → most in need of attention, so a
/// single tap on the column surfaces the tenants worth looking at.
extension AdminCompanyDisplayStatusOrder on AdminCompanyDisplayStatus {
  int get sortRank => switch (this) {
        AdminCompanyDisplayStatus.active => 0,
        AdminCompanyDisplayStatus.pendingPayment => 1,
        AdminCompanyDisplayStatus.inactive => 2,
        AdminCompanyDisplayStatus.deactivated => 3,
        AdminCompanyDisplayStatus.unknown => 4,
      };
}

/// The table's current sort. Immutable — [toggled] returns a new value.
class AdminCompaniesSort {
  final AdminCompanySortColumn column;
  final bool ascending;

  const AdminCompaniesSort({required this.column, required this.ascending});

  /// Matches the server's own ordering (`creationDate` descending), so the
  /// first paint is not a client-side reshuffle of what just arrived.
  static const AdminCompaniesSort initial = AdminCompaniesSort(
    column: AdminCompanySortColumn.creationDate,
    ascending: false,
  );

  /// The sort after tapping [tapped]: re-tapping the active column flips
  /// direction, tapping a new one adopts that column's natural direction.
  AdminCompaniesSort toggled(AdminCompanySortColumn tapped) {
    if (tapped == column) {
      return AdminCompaniesSort(column: column, ascending: !ascending);
    }
    return AdminCompaniesSort(
      column: tapped,
      ascending: tapped.defaultAscending,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminCompaniesSort &&
      other.column == column &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(column, ascending);
}
