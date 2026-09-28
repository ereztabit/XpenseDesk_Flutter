import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// A minimal SignalR client: JSON hub protocol v1 over a browser WebSocket,
/// no negotiate (FS-1007 S1.01, backend api-guide §9.2).
///
/// Deliberately small: the app only *receives* server pushes on one hub, so
/// there is no invoke/stream support, no transport fallback and no
/// reconnect here — reconnecting (with a fresh ticket) is the caller's job,
/// signalled through [closed].
class SignalRJsonSocket {
  SignalRJsonSocket(this.url, {required this.onInvocation});

  /// Full `wss://…/hubs/…?access_token=…` URL.
  final String url;

  /// Called for every server invocation (`type: 1`) with its target and
  /// arguments.
  final void Function(String target, List<dynamic> arguments) onInvocation;

  static const _recordSeparator = '\u001e';
  static const _pingInterval = Duration(seconds: 15);

  /// The server pings every 15 s; silence for longer than this means the
  /// connection is dead even if the browser has not noticed yet.
  static const _serverTimeout = Duration(seconds: 30);

  web.WebSocket? _socket;
  final _handshake = Completer<void>();
  final _closed = Completer<void>();
  Timer? _pingTimer;
  Timer? _silenceTimer;
  String _buffer = '';

  /// Completes (never errors) once the connection is gone, for any reason.
  Future<void> get closed => _closed.future;

  /// Opens the socket and completes after a successful handshake. Throws
  /// [StateError] when the upgrade or the handshake is refused.
  Future<void> start() {
    final socket = web.WebSocket(url);
    _socket = socket;

    socket.onopen = ((web.Event _) {
      _send({'protocol': 'json', 'version': 1});
      _pingTimer = Timer.periodic(_pingInterval, (_) => _send({'type': 6}));
      _armSilenceTimer();
    }).toJS;

    socket.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>()) _receive((data as JSString).toDart);
    }).toJS;

    socket.onclose = ((web.Event _) => _finish()).toJS;
    socket.onerror = ((web.Event _) => _finish()).toJS;

    return _handshake.future;
  }

  void close() {
    _socket?.close();
    _finish();
  }

  void _send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null || socket.readyState != web.WebSocket.OPEN) return;
    socket.send('${jsonEncode(message)}$_recordSeparator'.toJS);
  }

  void _armSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_serverTimeout, close);
  }

  void _receive(String chunk) {
    _armSilenceTimer();
    _buffer += chunk;
    while (true) {
      final end = _buffer.indexOf(_recordSeparator);
      if (end < 0) return;
      final frame = _buffer.substring(0, end);
      _buffer = _buffer.substring(end + 1);
      _handleFrame(frame);
    }
  }

  void _handleFrame(String frame) {
    final Object? decoded;
    try {
      decoded = jsonDecode(frame);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    // The first frame is the handshake response: `{}` or `{"error": …}`.
    if (!_handshake.isCompleted) {
      if (decoded['error'] != null) {
        _handshake.completeError(StateError('SignalR handshake refused'));
        close();
      } else {
        _handshake.complete();
      }
      return;
    }

    switch (decoded['type']) {
      case 1: // invocation
        final target = decoded['target'];
        final arguments = decoded['arguments'];
        if (target is String && arguments is List) {
          onInvocation(target, arguments);
        }
      case 7: // close
        close();
    }
  }

  void _finish() {
    _pingTimer?.cancel();
    _silenceTimer?.cancel();
    if (!_handshake.isCompleted) {
      _handshake.completeError(StateError('SignalR connection failed'));
    }
    if (!_closed.isCompleted) _closed.complete();
  }
}
