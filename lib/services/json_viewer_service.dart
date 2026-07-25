import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Opens raw JSON in the browser so it can be inspected outside the app.
/// Used by dev-only debug tools — no in-app rendering, the browser shows the
/// document.
class JsonViewerService {
  /// Pretty-prints [json] and opens it in a new browser tab.
  ///
  /// Falls back to downloading it as [filename] when the popup blocker refuses
  /// the tab. That happens when the caller awaited a network round-trip before
  /// getting here: the tap's user-gesture credit is spent by then, so the tab is
  /// not guaranteed. A download is never blocked, so the button always produces
  /// the JSON one way or the other.
  static void openInNewTab(Map<String, dynamic> json, String filename) {
    final pretty = const JsonEncoder.withIndent('  ').convert(json);
    final blob = web.Blob(
      [pretty.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final objectUrl = web.URL.createObjectURL(blob);

    if (web.window.open(objectUrl, '_blank') != null) {
      // Deliberately not revoked — the new tab reads the object URL after this
      // returns, and revoking would blank the tab. It dies with the page.
      return;
    }

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = objectUrl;
    anchor.download = filename;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
  }
}
