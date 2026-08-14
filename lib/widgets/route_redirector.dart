import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a spinner and replaces the current route with [route] on the next
/// frame. Used by the auth gates ([AuthGate], [AdminAuthGate]) to bounce a
/// session that does not belong on the requested route.
class RouteRedirector extends StatefulWidget {
  final String route;

  const RouteRedirector({super.key, required this.route});

  @override
  State<RouteRedirector> createState() => _RouteRedirectorState();
}

class _RouteRedirectorState extends State<RouteRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
