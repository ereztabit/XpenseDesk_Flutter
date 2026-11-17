import 'package:flutter/material.dart';

import '../router.dart';

/// The route [generateRoute] builds for [name], with its page transition
/// removed: the new page replaces the old one in a single frame.
///
/// For in-place switches where the surrounding chrome stays put (the
/// sheet-type bar), so the platform default - a full-screen slide on iOS - only
/// reads as the whole page jumping. Everything else keeps the default.
Route<dynamic> instantRoute(String name) {
  final settings = RouteSettings(name: name);
  final route = generateRoute(settings);
  if (route is! MaterialPageRoute) return route;
  return PageRouteBuilder<dynamic>(
    settings: settings,
    pageBuilder: (context, _, _) => route.builder(context),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
