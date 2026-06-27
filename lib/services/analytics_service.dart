import 'dart:js_interop';

/// Fires GA4 events through the gtag.js layer already loaded in web/index.html.
///
/// gtag.js owns the client_id / session (via the _ga cookie), so these events
/// tie to the same users as pageview tracking. No api_secret, no UUID, no http.
///
/// Off-prod, index.html defines gtag() as a no-op queue with no script to drain
/// it, so calls here are silently dropped. Every call is wrapped so analytics
/// can never crash the app or block the user flow.
class AnalyticsService {
  void trackEvent(String name, {Map<String, Object?> params = const {}}) {
    try {
      _gtag('event', name, params.jsify());
    } catch (_) {
      // Swallow — gtag missing or any interop error must never surface.
    }
  }
}

@JS('gtag')
external void _gtag(String command, String eventName, [JSAny? params]);
