import 'dart:async';

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
/// Loaded when the header first mounts and on every live-connection
/// (re)connect ([refresh]); in between, S1.01 pushes keep it current
/// ([applyPush]). Rebuilds on a user change so one account's batches never
/// show under another.
class BulkUploadBatchesNotifier extends AsyncNotifier<List<BulkUploadBatch>> {
  @override
  Future<List<BulkUploadBatch>> build() {
    ref.watch(userInfoProvider.select((u) => u?.email));
    return ref.read(bulkUploadServiceProvider).getBatches();
  }

  /// Re-fetches without dropping to a loading state, so the panel keeps its
  /// cards while it reloads.
  Future<void> refresh() async {
    final before = state.asData?.value;
    final next = await AsyncValue.guard(
      () => ref.read(bulkUploadServiceProvider).getBatches(),
    );
    if (!ref.mounted) return;
    state = next;
    final after = next.asData?.value;
    if (after != null) _refreshSheetsIfFiled(before, after);
  }

  /// Applies one live `batchUpdated` push. Ignored until the first load has
  /// landed — the load that follows every connect brings the batch anyway.
  void applyPush(BulkUploadBatch pushed) {
    final before = state.asData?.value;
    if (before == null) return;
    final after = mergeBatch(before, pushed);
    if (identical(after, before)) return;
    state = AsyncData(after);
    _refreshSheetsIfFiled(before, after);
  }

  /// Files that became expenses since [before] mean My expenses is showing a
  /// stale sheet: refetch it, and mark those expenses "just added" so their
  /// rows animate in. Runs per push, so the list grows file by file.
  void _refreshSheetsIfFiled(
    List<BulkUploadBatch>? before,
    List<BulkUploadBatch> after,
  ) {
    final filed = newlyCreatedExpenseIds(before, after);
    if (filed.isEmpty) return;
    ref.read(recentlyFiledExpensesProvider.notifier).add(filed);
    ref.invalidate(mySheetsProvider);
    ref.invalidate(sheetDetailProvider);
  }
}

/// Expenses a bulk batch filed in the last few seconds — the rows My
/// expenses highlights as "just added". Each id leaves the set on its own
/// after [_lifetime], long enough for the list refetch to land.
class RecentlyFiledExpensesNotifier extends Notifier<Set<String>> {
  static const _lifetime = Duration(seconds: 8);
  final List<Timer> _timers = [];

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers) {
        t.cancel();
      }
    });
    return const {};
  }

  void add(Set<String> expenseIds) {
    state = {...state, ...expenseIds};
    late final Timer timer;
    timer = Timer(_lifetime, () {
      _timers.remove(timer);
      if (ref.mounted) state = state.difference(expenseIds);
    });
    _timers.add(timer);
  }
}

final recentlyFiledExpensesProvider =
    NotifierProvider<RecentlyFiledExpensesNotifier, Set<String>>(
  RecentlyFiledExpensesNotifier.new,
);

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
