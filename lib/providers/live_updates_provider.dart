import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bulk_upload_batch.dart';
import '../services/notifications_service.dart';
import '../services/signalr_json_socket.dart';
import 'auth_provider.dart';
import 'bulk_upload_provider.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

/// The app's live connection to the notifications hub (FS-1007 S1.01,
/// backend api-guide §9). State: whether it is connected right now.
///
/// Up while someone is signed in and the company's bulk-upload flag is on;
/// torn down and rebuilt when either changes (logout, account switch, flag
/// off). Every (re)connect gets a fresh single-use ticket and reloads the
/// batches once — pushes are deltas, and that reload is how anything sent
/// while disconnected is recovered. A dropped connection retries with
/// backoff (1, 2, 5, 10, then every 30 s).
///
/// Not autoDispose on purpose: the header — and with it the bell that
/// watches this — is rebuilt on every navigation, and the socket must
/// survive that.
class LiveUpdatesNotifier extends Notifier<bool> {
  static const _retryDelays = [1, 2, 5, 10, 30];
  static const _batchUpdated = 'batchUpdated';

  SignalRJsonSocket? _socket;
  Timer? _retryTimer;
  int _attempt = 0;

  /// Bumped on every rebuild; an in-flight connect from an older build sees
  /// the mismatch and stands down.
  int _generation = 0;

  @override
  bool build() {
    final email = ref.watch(userInfoProvider.select((u) => u?.email));
    final enabled = ref.watch(isBulkUploadEnabledProvider);

    final generation = ++_generation;
    _attempt = 0;
    ref.onDispose(_teardown);

    if (email != null && enabled) {
      Future.microtask(() => _connect(generation));
    }
    return false;
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  void _teardown() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _socket?.close();
    _socket = null;
  }

  Future<void> _connect(int generation) async {
    if (!_isCurrent(generation)) return;
    final service = ref.read(notificationsServiceProvider);

    String? ticket;
    try {
      ticket = await service.getTicket();
    } catch (_) {
      ticket = null;
    }
    if (!_isCurrent(generation)) return;
    if (ticket == null) {
      _scheduleRetry(generation);
      return;
    }

    final socket = service.openSocket(ticket, onInvocation: _onInvocation);
    _socket = socket;
    try {
      await socket.start();
    } catch (_) {
      if (_isCurrent(generation)) _scheduleRetry(generation);
      return;
    }
    if (!_isCurrent(generation)) {
      socket.close();
      return;
    }

    _attempt = 0;
    state = true;
    unawaited(ref.read(bulkUploadBatchesProvider.notifier).refresh());

    await socket.closed;
    if (!_isCurrent(generation) || !identical(_socket, socket)) return;
    _socket = null;
    state = false;
    _scheduleRetry(generation);
  }

  void _scheduleRetry(int generation) {
    final seconds =
        _retryDelays[math.min(_attempt, _retryDelays.length - 1)];
    _attempt++;
    _retryTimer?.cancel();
    _retryTimer =
        Timer(Duration(seconds: seconds), () => _connect(generation));
  }

  void _onInvocation(String target, List<dynamic> arguments) {
    if (!ref.mounted || target != _batchUpdated || arguments.isEmpty) return;
    final payload = arguments.first;
    if (payload is! Map<String, dynamic>) return;
    ref
        .read(bulkUploadBatchesProvider.notifier)
        .applyPush(BulkUploadBatch.fromJson(payload));
  }
}

final liveUpdatesProvider = NotifierProvider<LiveUpdatesNotifier, bool>(
  LiveUpdatesNotifier.new,
);
