import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'active_badge.dart';

class MasterTable extends StatelessWidget {
  final List<ExpensesAnalysisSummaryRow> rows;
  final String? selectedCycleId;
  final String locale;
  final String currency;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelectCycle;

  const MasterTable({
    super.key,
    required this.rows,
    required this.selectedCycleId,
    required this.locale,
    required this.currency,
    required this.l10n,
    required this.onSelectCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.muted.withAlpha(128),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.reportCyclePrefix,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedForeground)),
              ),
              Text(l10n.totalApprovedLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedForeground)),
            ],
          ),
        ),
        ...rows.map((row) {
          final isSelected = row.cycleId == selectedCycleId;
          return InkWell(
            onTap: () => onSelectCycle(row.cycleId),
            child: Container(
              color: isSelected ? AppTheme.primary.withAlpha(13) : null,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(row.cycleLabel,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: AppTheme.foreground)),
                        if (row.isActive) ...[
                          const SizedBox(width: 8),
                          ActiveBadge(l10n: l10n),
                        ],
                      ],
                    ),
                  ),
                  Text(row.totalApproved.toCurrency(locale, currency),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: AppTheme.foreground)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
