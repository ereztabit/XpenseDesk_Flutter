import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bulk_upload_batch.dart';
import '../services/bulk_upload_service.dart';
import '../utils/bulk_upload_utils.dart';
import 'auth_provider.dart';
import 'company_provider.dart';
import 'expense_sheet_provider.dart';

final bulkUploadServiceProvider = Provider<BulkUploadService>((ref) {
  return BulkUploadService();
});

/// The company's bulk-upload flag (api-guide §2). False while the company is
/// still loading or failed to load, so the feature never flashes on.
final isBulkUploadEnabledProvider = Provider<bool>((ref) {
  return ref
          .watch(companyProvider)
          .asData
          ?.value
          .configuration
          .isBulkUploadEnabled ??
      false;
});

/// The caller's recent batches (GET /api/bulk-uploads) behind the bell.
///
/// S1 has no push (UI/UX guide §6.2): fetched when the header first mounts,
/// and again via [refresh] on panel open and the Refresh button. Rebuilds on a
/// user change so one account's batches never show under another.
class BulkUploadBatchesNotifier extends AsyncNotifier<List<BulkUploadBatch>> {
  @override
  Future<List<BulkUploadBatch>> build() {
    ref.watch(userInfoProvider.select((u) => u?.email));
    return ref.read(bulkUploadServiceProvider).getBatches();
  }

  /// Re-fetches without dropping to a loading state, so the panel keeps its
  /// cards while the Refresh icon spins.
  ///
  /// A batch that filed expenses since the last fetch means My expenses is
  /// showing a stale sheet, so the sheet list and details are refetched too —
  /// the worker adds lines behind the app's back.
  Future<void> refresh() async {
    final before = state.asData?.value;
    final next = await AsyncValue.guard(
      () => ref.read(bulkUploadServiceProvider).getBatches(),
    );
    if (!ref.mounted) return;
    state = next;
    final after = next.asData?.value;
    if (after != null && hasNewlyFiledExpenses(before, after)) {
      ref.invalidate(mySheetsProvider);
      ref.invalidate(sheetDetailProvider);
    }
  }
}

final bulkUploadBatchesProvider =
    AsyncNotifierProvider<BulkUploadBatchesNotifier, List<BulkUploadBatch>>(
  BulkUploadBatchesNotifier.new,
);

/// When this user last opened the notifications panel, kept on the device
/// (§6.1: the S1 unread badge is device-local). Null = never opened here.
class NotificationsLastSeenNotifier extends Notifier<DateTime?> {
  String? _key;

  @override
  DateTime? build() {
    final email = ref.watch(userInfoProvider.select((u) => u?.email));
    _key = email == null ? null : 'notificationsLastSeen:$email';
    _load();
    return null;
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(key);
    // `state == null`: a markSeen that landed before this read wins.
    if (millis != null && ref.mounted && key == _key && state == null) {
      state = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }

  /// Marks everything in [batches] as seen. Takes the later of the device
  /// clock and the newest server timestamp, so a device clock running behind
  /// the server can't leave a just-seen batch flagged as new.
  Future<void> markSeen(List<BulkUploadBatch> batches) async {
    var seen = DateTime.now().toUtc();
    for (final b in batches) {
      if (b.lastEventAt.isAfter(seen)) seen = b.lastEventAt;
    }
    state = seen;
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, seen.millisecondsSinceEpoch);
  }
}

final notificationsLastSeenProvider =
    NotifierProvider<NotificationsLastSeenNotifier, DateTime?>(
  NotificationsLastSeenNotifier.new,
);
