import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart'; // ProviderOrFamily

import '../models/admin_ai_profile.dart';
import '../models/admin_ai_scan_review.dart';
import '../models/admin_ai_usage.dart';
import '../services/admin_ai_profiles_service.dart';
import '../services/admin_ai_usage_service.dart';
import '../utils/admin_ai_utils.dart';

/// FS-1026 Receipt AI admin module state. Every provider here is listed in
/// [adminReceiptAiCachedProviders], which admin disconnect invalidates.

/// A plain settable value (view state).
class AdminAiValue<T> extends Notifier<T> {
  AdminAiValue(this._initial);
  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

final adminAiProfilesServiceProvider = Provider<AdminAiProfilesService>((ref) => AdminAiProfilesService());
final adminAiUsageServiceProvider = Provider<AdminAiUsageService>((ref) => AdminAiUsageService());

// ---- profiles ----

/// autoDispose: re-read on every visit - another admin may have changed it.
final adminAiProfilesProvider = FutureProvider.autoDispose<List<AdminAiProfileRow>>(
    (ref) => ref.read(adminAiProfilesServiceProvider).getProfiles());

final adminAiShowArchivedProvider =
    NotifierProvider<AdminAiValue<bool>, bool>(() => AdminAiValue(false));

final adminAiProfileProvider = FutureProvider.autoDispose.family<AdminAiProfileDetail, int>(
    (ref, id) => ref.read(adminAiProfilesServiceProvider).getProfile(id));

final adminAiVersionsProvider = FutureProvider.autoDispose.family<List<AdminAiVersionItem>, int>(
    (ref, id) => ref.read(adminAiProfilesServiceProvider).getVersions(id));

// ---- companies ----

final adminAiCompaniesProvider = FutureProvider.autoDispose<List<AdminAiCompanyRow>>(
    (ref) => ref.read(adminAiUsageServiceProvider).getCompanies());

final adminAiCompanySearchProvider =
    NotifierProvider<AdminAiValue<String>, String>(() => AdminAiValue(''));

final adminAiCompanyProfileFilterProvider =
    NotifierProvider<AdminAiValue<int?>, int?>(() => AdminAiValue(null));

final adminAiSelectedCompaniesProvider =
    NotifierProvider<AdminAiValue<Set<String>>, Set<String>>(() => AdminAiValue(const {}));

// ---- usage ----

final adminAiUsageFiltersProvider = NotifierProvider<AdminAiValue<AdminAiUsageFilters>, AdminAiUsageFilters>(
    () => AdminAiValue(AdminAiUsageFilters.none));

final adminAiGroupByProvider =
    NotifierProvider<AdminAiValue<AdminAiGroupBy>, AdminAiGroupBy>(() => AdminAiValue(AdminAiGroupBy.model));

final adminAiUsageProvider = FutureProvider.autoDispose<AdminAiUsage>((ref) => ref
    .read(adminAiUsageServiceProvider)
    .getUsage(ref.watch(adminAiGroupByProvider), ref.watch(adminAiUsageFiltersProvider)));

/// The usage row whose scans are listed: `picked == false` = none; `key` null
/// = the "not recorded" row.
typedef AdminAiPickedRow = ({bool picked, String? key});

final adminAiPickedRowProvider = NotifierProvider<AdminAiValue<AdminAiPickedRow>, AdminAiPickedRow>(
    () => AdminAiValue((picked: false, key: null)));

/// Review-status switch over the scan list: null all, 0 not reviewed, 1, 2.
final adminAiReviewStatusFilterProvider =
    NotifierProvider<AdminAiValue<int?>, int?>(() => AdminAiValue(0));

final adminAiScansProvider = FutureProvider.autoDispose<List<AdminAiScanRow>>((ref) async {
  final picked = ref.watch(adminAiPickedRowProvider);
  if (!picked.picked) return const [];
  return ref.read(adminAiUsageServiceProvider).getScans(
        ref.watch(adminAiGroupByProvider),
        picked.key,
        ref.watch(adminAiUsageFiltersProvider),
        reviewStatusId: ref.watch(adminAiReviewStatusFilterProvider),
      );
});

/// The scan list the review screen walks with Previous / Next unreviewed.
final adminAiScanQueueProvider =
    NotifierProvider<AdminAiValue<List<String>>, List<String>>(() => AdminAiValue(const []));

/// Expenses reviewed in this session (skipped by Next unreviewed).
final adminAiReviewedIdsProvider =
    NotifierProvider<AdminAiValue<Set<String>>, Set<String>>(() => AdminAiValue(const {}));

final adminAiScanReviewProvider = FutureProvider.autoDispose.family<AdminAiScanReview, String>(
    (ref, expenseId) => ref.read(adminAiUsageServiceProvider).getScanReview(expenseId));

final List<ProviderOrFamily> adminReceiptAiCachedProviders = [
  adminAiProfilesProvider,
  adminAiShowArchivedProvider,
  adminAiProfileProvider,
  adminAiVersionsProvider,
  adminAiCompaniesProvider,
  adminAiCompanySearchProvider,
  adminAiCompanyProfileFilterProvider,
  adminAiSelectedCompaniesProvider,
  adminAiUsageFiltersProvider,
  adminAiGroupByProvider,
  adminAiUsageProvider,
  adminAiPickedRowProvider,
  adminAiReviewStatusFilterProvider,
  adminAiScansProvider,
  adminAiScanQueueProvider,
  adminAiReviewedIdsProvider,
  adminAiScanReviewProvider,
];
