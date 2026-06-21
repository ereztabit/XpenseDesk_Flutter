// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kIosHintDismissedKey = 'ios_install_hint_dismissed';

/// Whether the user dismissed the iOS install banner. Persisted to localStorage
/// so the banner does not reappear on every load. The "Install app" menu item
/// stays available regardless of this flag.
final iosHintDismissedProvider =
    NotifierProvider<IosHintDismissedNotifier, bool>(
  IosHintDismissedNotifier.new,
);

class IosHintDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => _readPersisted();

  static bool _readPersisted() {
    try {
      return html.window.localStorage[_kIosHintDismissedKey] == '1';
    } catch (_) {
      return false;
    }
  }

  void dismiss() {
    try {
      html.window.localStorage[_kIosHintDismissedKey] = '1';
    } catch (_) {/* storage unavailable — keep in-memory state only */}
    state = true;
  }
}

/// In-memory, session-scoped guard so the install drawer auto-opens at most once
/// per load even though [AppHeader] (which hosts the trigger) mounts on every
/// authenticated screen. Resets on reload — the persisted [iosHintDismissedProvider]
/// is what prevents it from reappearing across loads.
final iosHintAutoShownProvider =
    NotifierProvider<IosHintAutoShownNotifier, bool>(
  IosHintAutoShownNotifier.new,
);

class IosHintAutoShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}
