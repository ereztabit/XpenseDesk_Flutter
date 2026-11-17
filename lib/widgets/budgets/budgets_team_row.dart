import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/manager_dashboard_provider.dart';
import '../../utils/manager_dashboard_state_utils.dart';
import '../manager_dashboard/invite_block.dart';
import '../manager_dashboard/teammates_strip.dart';

/// The Monthly dashboard's team line on the Budgets dashboard (user decision
/// 2026-11-17: Budgets may be a company's only module): [TeammatesStrip]
/// ("2 Teammates · 2 managers · Manage"), or [InviteBlock] while the company
/// has no teammates yet - the same rule as the Monthly dashboard. Nothing
/// while the users load.
class BudgetsTeamRow extends ConsumerWidget {
  const BudgetsTeamRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(managerDashboardStateProvider).asData?.value;
    if (data == null) return const SizedBox.shrink();
    if (data.state == ManagerDashboardState.empty) return const InviteBlock();
    return TeammatesStrip(count: data.teammateCount, managerCount: data.managerCount);
  }
}
