import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A callback that returns true if navigation should proceed.
/// Screens with unsaved changes register one via [FormBehaviorMixin];
/// widgets like AppHeader read it before triggering logo navigation.
typedef NavigationGuard = Future<bool> Function();

class NavigationGuardNotifier extends Notifier<NavigationGuard?> {
  @override
  NavigationGuard? build() => null;

  void setGuard(NavigationGuard? guard) => state = guard;

  /// Clears [guard] only if it is still the active one.
  ///
  /// A leaving screen must not blank a guard the screen replacing it has
  /// already installed. That is a real ordering: the new screen registers in its
  /// post-frame callback, which runs at the end of the current frame, while the
  /// old screen's clear is deferred past the frame (its `dispose` runs inside
  /// the build phase, where provider writes are forbidden). So by the time the
  /// clear lands, the guard on record is usually somebody else's.
  void clearGuard(NavigationGuard guard) {
    if (identical(state, guard)) state = null;
  }
}

final navigationGuardProvider =
    NotifierProvider<NavigationGuardNotifier, NavigationGuard?>(
  NavigationGuardNotifier.new,
);
