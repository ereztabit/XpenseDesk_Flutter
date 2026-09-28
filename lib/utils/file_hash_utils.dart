import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Lower-case SHA-256 hex of [bytes], via the browser's Web Crypto API (no
/// Dart dependency needed). Returns null when the browser refuses — Web Crypto
/// only exists in secure contexts — so callers must treat null as "unknown",
/// never as a match.
///
/// The server derives `stagedFileId` from the same hash, so this is also what
/// lets the client spot an identical file before it is uploaded twice.
Future<String?> sha256Hex(Uint8List bytes) async {
  try {
    final digest = await web.window.crypto.subtle
        .digest('SHA-256'.toJS, bytes.toJS)
        .toDart;
    final out = (digest as JSArrayBuffer).toDart.asUint8List();
    final hex = StringBuffer();
    for (final b in out) {
      hex.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  } catch (_) {
    return null;
  }
}
