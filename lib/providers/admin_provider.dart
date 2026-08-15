import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart'; // ProviderOrFamily
import '../models/admin_companies_sort.dart';
import '../models/admin_company_row.dart';
import '../models/admin_company_user_row.dart';
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

/// Whether deactivated companies are listed. Default **false** — the list is a
/// support tool, and a company nobody can log into is not the one on the phone.
class AdminShowInactiveCompaniesNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final adminShowInactiveCompaniesProvider =
    NotifierProvider<AdminShowInactiveCompaniesNotifier, bool>(
  AdminShowInactiveCompaniesNotifier.new,
);

/// The rows actually rendered: [adminCompaniesProvider] with the current
/// deactivated filter, search and sort applied. Empty while loading or on
/// error — the screen reads the async state itself for those.
final visibleAdminCompaniesProvider = Provider<List<AdminCompanyRow>>((ref) {
  final companiesAsync = ref.watch(adminCompaniesProvider);
  final search = ref.watch(adminCompanySearchProvider);
  final sort = ref.watch(adminCompaniesSortProvider);
  final showInactive = ref.watch(adminShowInactiveCompaniesProvider);

  return companiesAsync.maybeWhen(
    data: (rows) => AdminCompaniesQuery.apply(
      rows,
      search: search,
      sort: sort,
      showInactive: showInactive,
    ),
    orElse: () => const [],
  );
});

/// The people of ONE company (`GET /api/admin/companies/{id}/users`) — the
/// impersonation picker (FS-1001).
///
/// Not a family: the screen shows one company at a time, and a family keyed by
/// company id would keep every company an agent ever opened alive in memory for
/// the whole session — customer data with no reason to linger. [load] replaces
/// the contents instead, so only the company on screen is held.
///
/// The state carries the company id alongside the rows so a consumer can tell
/// "these are the people you asked for" from "these are the previous company's
/// people, still here because the fetch has not landed". See [AdminCompanyUsers].
class AdminCompanyUsersNotifier extends AsyncNotifier<AdminCompanyUsers> {
  String? _companyId;

  @override
  Future<AdminCompanyUsers> build() async {
    ref.keepAlive();
    return AdminCompanyUsers.empty;
  }

  Future<void> load(String companyId) async {
    _companyId = companyId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final rows =
          await ref.read(adminServiceProvider).getCompanyUsers(companyId);
      return AdminCompanyUsers(companyId: companyId, rows: rows);
    });
  }

  Future<void> refresh() async {
    final companyId = _companyId;
    if (companyId != null) {
      await load(companyId);
    }
  }
}

final adminCompanyUsersProvider =
    AsyncNotifierProvider<AdminCompanyUsersNotifier, AdminCompanyUsers>(
  AdminCompanyUsersNotifier.new,
);

/// Whether deactivated people are shown. Default **false** — an agent on a call
/// is looking for someone who can still use the product, so the common case is
/// the short list.
class AdminShowInactiveUsersNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final adminShowInactiveUsersProvider =
    NotifierProvider<AdminShowInactiveUsersNotifier, bool>(
  AdminShowInactiveUsersNotifier.new,
);

/// Free-text search over the people list — matched against name AND email,
/// because an agent has whichever one the caller gave them.
class AdminCompanyUserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final adminCompanyUserSearchProvider =
    NotifierProvider<AdminCompanyUserSearchNotifier, String>(
  AdminCompanyUserSearchNotifier.new,
);

// The rendered rows are NOT a provider: they depend on which company the screen
// is showing, which is widget state, not provider state. AdminCompanyUsersQuery
// derives them from [adminCompanyUsersProvider] +
// [adminShowInactiveUsersProvider] + the screen's company id.
//
// No sorting anywhere — the API already returns managers first, then employees,
// each by name. Re-sorting client-side would be a second, drifting definition of
// an order the server is responsible for.

/// Every admin-shell provider holding state from the current session — cached
/// server data and the view state over it. Disconnect invalidates all of them
/// so nothing survives into the next login (see
/// docs/bugs/stale-data-after-switching-company.md for the pattern this
/// deliberately avoids). Add new admin modules' providers here.
final List<ProviderOrFamily> adminCachedProviders = [
  adminCompaniesProvider,
  adminCompanySearchProvider,
  adminCompaniesSortProvider,
  adminShowInactiveCompaniesProvider,
  adminCompanyUsersProvider,
  adminShowInactiveUsersProvider,
  adminCompanyUserSearchProvider,
];
