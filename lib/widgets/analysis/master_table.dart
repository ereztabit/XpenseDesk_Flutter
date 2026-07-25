import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../selectable_scope.dart';
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

  static final _colDivider = Container(width: 1, color: AppTheme.border);

  @override
  Widget build(BuildContext context) {
    final displayRows = rows.reversed.toList();

    return SelectableScope(
      child: Column(
        children: [
          // ── header ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 160),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        l10n.reportCyclePrefix,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                  ),
                  _colDivider,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      l10n.totalApprovedLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
          // ── data rows ───────────────────────────────────────────────────────
          ...List.generate(displayRows.length, (i) {
            final row = displayRows[i];
            final isSelected = row.cycleId == selectedCycleId;
            final isLast = i == displayRows.length - 1;

            return InkWell(
              onTap: () => onSelectCycle(row.cycleId),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withAlpha(40) : null,
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppTheme.border),
                        ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 160),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                row.cycleLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppTheme.foreground,
                                ),
                              ),
                              if (row.isActive) ...[
                                const SizedBox(width: 8),
                                ActiveBadge(l10n: l10n),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _colDivider,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          row.totalApproved.toCurrency(locale, currency),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
