import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A callback that returns true if navigation should proceed.
/// Screens with unsaved changes register one via [FormBehaviorMixin];
/// widgets like AppHeader read it before triggering logo navigation.
typedef NavigationGuard = Future<bool> Function();

class NavigationGuardNotifier extends Notifier<NavigationGuard?> {
  @override
  NavigationGuard? build() => null;

  void setGuard(NavigationGuard? guard) => state = guard;
}

final navigationGuardProvider =
    NotifierProvider<NavigationGuardNotifier, NavigationGuard?>(
  NavigationGuardNotifier.new,
);
