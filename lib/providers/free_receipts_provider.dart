import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/free_receipts.dart';
import '../models/user_info.dart';
import '../services/free_receipts_service.dart';
import 'auth_provider.dart';
import 'company_provider.dart';

final freeReceiptsServiceProvider = Provider<FreeReceiptsService>((ref) {
  return FreeReceiptsService();
});

/// The signed-in user's free receipts (FS-1007 S3, api-guide §11.1).
///
/// Loaded once per user and refreshed after anything that changes it: an
/// expense saved or deleted, a batch sent or completed, a refused scan
/// ([refresh]), and a change to the company's plan (a payment lifts the
/// limit). A platform admin has
/// none, so it is never fetched for one. Rebuilds on a user change so one
/// account's count never shows under another.
class FreeReceiptsNotifier extends AsyncNotifier<FreeReceipts> {
  /// The company's plan status, as last seen - what decides whether it is
  /// limited.
  String? _companyKey;

  @override
  Future<FreeReceipts> build() async {
    final user = ref.watch(
        userInfoProvider.select((u) => (email: u?.email, roleId: u?.roleId)));
    if (user.email == null || user.roleId == UserInfo.platformAdminRoleId) {
      return FreeReceipts.unlimited;
    }

    // Reload - without a loading flicker - when a new company load shows a
    // different plan. The loading state between two loads is skipped, so a
    // refresh that changes nothing costs nothing.
    _companyKey = null;
    ref.listen(companyProvider, (_, next) {
      final company = next.asData?.value;
      if (company == null) return;
      final key = company.subscriptionStatus;
      final changed = _companyKey != null && _companyKey != key;
      _companyKey = key;
      if (changed) refresh();
    }, fireImmediately: true);

    return ref.read(freeReceiptsServiceProvider).getMine();
  }

  /// Re-fetches without dropping to a loading state, so the meter never
  /// flickers while it reloads. A failed reload keeps the last known count.
  Future<void> refresh() async {
    final user = ref.read(userInfoProvider);
    if (user == null || user.roleId == UserInfo.platformAdminRoleId) return;
    final next = await AsyncValue.guard(
      () => ref.read(freeReceiptsServiceProvider).getMine(),
    );
    if (!ref.mounted) return;
    if (next.hasValue || state.asData == null) state = next;
  }
}

final freeReceiptsProvider =
    AsyncNotifierProvider<FreeReceiptsNotifier, FreeReceipts>(
  FreeReceiptsNotifier.new,
);

/// The free receipts to act on: the loaded value, or "no limit" while it is
/// loading or failed — the server enforces the limit anyway, so the client
/// never blocks a user on a count it could not load.
final currentFreeReceiptsProvider = Provider<FreeReceipts>((ref) {
  return ref.watch(freeReceiptsProvider).asData?.value ??
      FreeReceipts.unlimited;
});
