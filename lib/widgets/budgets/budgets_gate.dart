import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/company_provider.dart';
import '../../utils/app_navigator.dart';
import '../route_redirector.dart';

/// Shows [child] only while Budgets are usable (flag + module) and, with
/// [managerOnly], for a manager. Otherwise bounces to the user's home
/// dashboard - a typed URL never reaches a Budgets page it may not use.
class BudgetsGate extends ConsumerWidget {
  const BudgetsGate({super.key, required this.child, this.managerOnly = true});

  final Widget child;
  final bool managerOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userInfoProvider);
    if (user == null || ref.watch(companyProvider).isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final allowed =
        ref.watch(isPettyCashEnabledProvider) && (!managerOnly || user.isManager);
    if (!allowed) {
      return RouteRedirector(
        route: user.isManager ? AppRoutes.managerDashboard : AppRoutes.employeeDashboard,
      );
    }
    return child;
  }
}
