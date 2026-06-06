import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/responsive_utils.dart';

/// Segmented pill that lets a manager switch the dashboard between Team Expenses
/// (`/dashboard`) and their own My Expenses (`/user/dashboard`).
///
/// Self-gates: renders nothing for non-managers, so both dashboards can drop it
/// in unconditionally. The active pill is derived from the current route name —
/// no local state. Tapping the inactive pill `pushReplacementNamed`s its route
/// (toggle semantics); tapping the active pill is a no-op.
class ManagerViewSwitcher extends ConsumerWidget {
  const ManagerViewSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    if (userInfo?.roleId != 1) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    final myExpensesActive = routeName.startsWith(AppRoutes.employeeDashboard);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.primary.withAlpha(77), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                label: l10n.teamExpenses,
                icon: Icons.people_outline,
                active: !myExpensesActive,
                onTap: myExpensesActive
                    ? () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.managerDashboard)
                    : null,
              ),
              _Pill(
                label: l10n.myExpenses,
                icon: Icons.receipt_long_outlined,
                active: myExpensesActive,
                onTap: myExpensesActive
                    ? null
                    : () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.employeeDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single pill. Active = filled primary; inactive = transparent with a
/// hover-to-foreground text transition. Tappable only when [onTap] is set.
class _Pill extends StatefulWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = context.isMobile ? 12.0 : 14.0;
    final Color fg = widget.active
        ? AppTheme.primaryForeground
        : (_hovered ? AppTheme.foreground : AppTheme.mutedForeground);

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: widget.active ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return Semantics(button: true, selected: widget.active, child: pill);
    }

    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(onTap: widget.onTap, child: pill),
      ),
    );
  }
}
