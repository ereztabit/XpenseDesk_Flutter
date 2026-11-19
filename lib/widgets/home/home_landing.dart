import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_login_navigator.dart';

/// `/home`: a spinner while [resolveHomeRoute] picks Monthly or Budgets, then
/// replaces itself with that page (D43). Where a signed-in user opening `/`
/// lands - Microsoft sign-in and a reopened app take this path.
class HomeLanding extends ConsumerStatefulWidget {
  const HomeLanding({super.key});

  @override
  ConsumerState<HomeLanding> createState() => _HomeLandingState();
}

class _HomeLandingState extends ConsumerState<HomeLanding> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(userInfoProvider);
      if (user == null) return;
      final route = await resolveHomeRoute(ref, isManager: user.isManager);
      if (mounted) Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppTheme.background,
    body: Center(child: CircularProgressIndicator()),
  );
}
