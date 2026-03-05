import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// A triple segmented-control toggle for the three expense statuses.
///
/// [selectedStatusId] — the currently active status (1=Pending, 2=Approved, 3=Declined).
/// [counts] — map of statusId → item count displayed as a badge inside each tab.
/// [onChanged] — callback with the newly selected statusId.
class ExpenseStatusToggle extends StatelessWidget {
  const ExpenseStatusToggle({
    super.key,
    required this.selectedStatusId,
    required this.counts,
    required this.onChanged,
  });

  final int selectedStatusId;
  final Map<int, int> counts;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statuses = [
      (id: 1, label: l10n.pending),
      (id: 2, label: l10n.approved),
      (id: 3, label: l10n.declined),
    ];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: statuses.map((s) {
          final isSelected = s.id == selectedStatusId;
          final count = counts[s.id] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(s.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius - 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(51),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryForeground
                              : AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 5),
                      _CountBadge(count: count, isSelected: isSelected),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.isSelected});

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryForeground.withAlpha(38)
            : AppTheme.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppTheme.primaryForeground : AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
