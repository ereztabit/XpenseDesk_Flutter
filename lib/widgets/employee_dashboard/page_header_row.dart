import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import 'view_mode_toggle.dart';

/// Page header for the employee dashboard.
///
/// Leading: title.
/// Trailing cluster: view-mode toggle (mobile + Draft + has expenses) and
/// the New-expense button (enabled only when [newExpenseEnabled]).
class PageHeaderRow extends StatelessWidget {
  const PageHeaderRow({
    super.key,
    required this.newExpenseEnabled,
    required this.showViewModeToggle,
    required this.onNewExpense,
  });

  final bool newExpenseEnabled;
  final bool showViewModeToggle;
  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderMedium, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.myExpenses,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: context.isMobile ? 18 : 24,
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showViewModeToggle) ...[
                const ViewModeToggle(),
                const SizedBox(width: 8),
              ],
              AppButton(
                label: l10n.newExpense,
                variant: AppButtonVariant.primary,
                icon: Icons.add,
                onPressed: newExpenseEnabled ? onNewExpense : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
