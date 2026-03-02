import 'package:flutter/material.dart';

/// Global navigator key used for navigation outside the widget tree
/// (e.g. from ApiService when a 401 Unauthorized response is received).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
