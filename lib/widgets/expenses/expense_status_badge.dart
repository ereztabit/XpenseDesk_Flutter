import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Small rounded pill showing the expense status.
///
/// Pending = amber background, white text.
/// Approved = green background, white text.
/// Declined = red background, white text.
class ExpenseStatusBadge extends StatelessWidget {
  final int expenseStatusId;

  const ExpenseStatusBadge({super.key, required this.expenseStatusId});

  Color _backgroundColor() => switch (expenseStatusId) {
        2 => AppTheme.success,
        3 => AppTheme.destructive,
        _ => AppTheme.amber,
      };

  String _label(AppLocalizations l10n) => switch (expenseStatusId) {
        2 => l10n.approved,
        3 => l10n.declined,
        _ => l10n.pending,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(l10n),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
