import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Small rounded pill showing the expense status.
///
/// Pending = amber background, white text.
/// Approved = green background, white text.
/// Declined = red background, white text.
/// When [isAiData] is true and status is pending, an AI chip is shown alongside.
class ExpenseStatusBadge extends StatelessWidget {
  final int expenseStatusId;
  final bool isAiData;

  const ExpenseStatusBadge({
    super.key,
    required this.expenseStatusId,
    this.isAiData = false,
  });

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

    final statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(l10n),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    if (!isAiData || expenseStatusId != 1) return statusPill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statusPill,
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(230),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 10, color: Colors.white),
              SizedBox(width: 3),
              Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
