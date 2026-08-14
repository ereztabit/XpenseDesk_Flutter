import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart'; // ProviderOrFamily
import '../models/admin_companies_sort.dart';
import '../models/admin_company_row.dart';
import '../services/admin_service.dart';
import '../utils/admin_companies_utils.dart';

/// Provider for AdminService singleton.
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

/// The platform-wide companies list (`GET /api/admin/companies`).
///
/// Uses keepAlive so an error state is sticky — the API is not retried on every
/// rebuild. Call [refresh] explicitly. Must be invalidated on disconnect so no
/// cross-company data survives into the next session.
class AdminCompaniesNotifier extends AsyncNotifier<List<AdminCompanyRow>> {
  @override
  Future<List<AdminCompanyRow>> build() async {
    ref.keepAlive();
    return _fetch();
  }

  Future<List<AdminCompanyRow>> _fetch() =>
      ref.read(adminServiceProvider).getCompanies();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminCompaniesProvider =
    AsyncNotifierProvider<AdminCompaniesNotifier, List<AdminCompanyRow>>(
  AdminCompaniesNotifier.new,
);

/// Free-text company-name search on the companies table.
class AdminCompanySearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final adminCompanySearchProvider =
    NotifierProvider<AdminCompanySearchNotifier, String>(
  AdminCompanySearchNotifier.new,
);

/// Which column the companies table is sorted by, and in which direction.
class AdminCompaniesSortNotifier extends Notifier<AdminCompaniesSort> {
  @override
  AdminCompaniesSort build() => AdminCompaniesSort.initial;

  /// Header tap: flips the active column, or switches to a new one.
  void toggle(AdminCompanySortColumn column) => state = state.toggled(column);
}

final adminCompaniesSortProvider =
    NotifierProvider<AdminCompaniesSortNotifier, AdminCompaniesSort>(
  AdminCompaniesSortNotifier.new,
);

/// The rows actually rendered: [adminCompaniesProvider] with the current search
/// and sort applied. Empty while loading or on error — the screen reads the
/// async state itself for those.
final visibleAdminCompaniesProvider = Provider<List<AdminCompanyRow>>((ref) {
  final companiesAsync = ref.watch(adminCompaniesProvider);
  final search = ref.watch(adminCompanySearchProvider);
  final sort = ref.watch(adminCompaniesSortProvider);

  return companiesAsync.maybeWhen(
    data: (rows) => AdminCompaniesQuery.apply(rows, search: search, sort: sort),
    orElse: () => const [],
  );
});

/// Every admin-shell provider holding state from the current session — cached
/// server data and the view state over it. Disconnect invalidates all of them
/// so nothing survives into the next login (see
/// docs/bugs/stale-data-after-switching-company.md for the pattern this
/// deliberately avoids). Add new admin modules' providers here.
final List<ProviderOrFamily> adminCachedProviders = [
  adminCompaniesProvider,
  adminCompanySearchProvider,
  adminCompaniesSortProvider,
];
