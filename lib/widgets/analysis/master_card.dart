import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import 'master_bar_chart.dart';
import 'master_table.dart';

enum MasterViewMode { chart, table }

class MasterCard extends StatefulWidget {
  final List<ExpensesAnalysisSummaryRow> rows;
  final String? selectedCycleId;
  final String locale;
  final String currency;
  final bool loading;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelectCycle;
  final VoidCallback? onExport;

  const MasterCard({
    super.key,
    required this.rows,
    required this.selectedCycleId,
    required this.locale,
    required this.currency,
    required this.loading,
    required this.l10n,
    required this.onSelectCycle,
    this.onExport,
  });

  @override
  State<MasterCard> createState() => _MasterCardState();
}

class _MasterCardState extends State<MasterCard> {
  MasterViewMode _viewMode = MasterViewMode.chart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.trending_up,
                    size: 16, color: AppTheme.mutedForeground),
                const SizedBox(width: 6),
                Text(widget.l10n.monthlyBreakdown,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mutedForeground)),
                const Spacer(),
                _buildConfigWidget(),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.rows.isEmpty ||
              widget.rows.every((r) => r.totalApproved == 0))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 40,
                        color: AppTheme.mutedForeground.withAlpha(102)),
                    const SizedBox(height: 12),
                    Text(widget.l10n.analysisNoData,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.mutedForeground, fontSize: 14)),
                  ],
                ),
              ),
            )
          else if (_viewMode == MasterViewMode.chart)
            MasterBarChart(
              rows: widget.rows,
              selectedCycleId: widget.selectedCycleId,
              locale: widget.locale,
              currency: widget.currency,
              l10n: widget.l10n,
              onSelectCycle: widget.onSelectCycle,
            )
          else
            MasterTable(
              rows: widget.rows,
              selectedCycleId: widget.selectedCycleId,
              locale: widget.locale,
              currency: widget.currency,
              l10n: widget.l10n,
              onSelectCycle: widget.onSelectCycle,
            ),
        ],
      ),
    );
  }

  Widget _buildConfigWidget() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle(
            icon: Icons.bar_chart,
            selected: _viewMode == MasterViewMode.chart,
            onTap: () => setState(() => _viewMode = MasterViewMode.chart),
          ),
          _toggle(
            icon: Icons.table_rows,
            selected: _viewMode == MasterViewMode.table,
            onTap: () => setState(() => _viewMode = MasterViewMode.table),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 14),
            label: Text(widget.l10n.export,
                style: const TextStyle(fontSize: 12)),
            onPressed: (widget.rows.isEmpty || widget.rows.every((r) => r.totalApproved == 0)) ? null : widget.onExport,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: 16,
            color: selected ? AppTheme.primary : AppTheme.mutedForeground),
      ),
    );
  }
}
