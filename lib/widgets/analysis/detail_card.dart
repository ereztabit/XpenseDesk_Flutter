import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_detail_state.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'active_badge.dart';
import 'category_bar_chart.dart';
import 'employee_bar_chart.dart';
import 'pivot_table.dart';

enum DetailViewMode { byCategory, byEmployee, pivotTable }

class DetailCard extends StatefulWidget {
  final ExpensesAnalysisSummaryRow? selectedRow;
  final ExpensesAnalysisDetailState? detailState;
  final bool loading;
  final String locale;
  final String currency;
  final String cycleId;
  final bool isMobile;
  final AppLocalizations l10n;
  final VoidCallback? onExport;
  final void Function(String cycleId,
      {String? employeeId, String? categoryAlias}) onDrillThrough;

  const DetailCard({
    super.key,
    required this.selectedRow,
    required this.detailState,
    required this.loading,
    required this.locale,
    required this.currency,
    required this.cycleId,
    required this.isMobile,
    required this.l10n,
    required this.onDrillThrough,
    this.onExport,
  });

  @override
  State<DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends State<DetailCard> {
  DetailViewMode _viewMode = DetailViewMode.byCategory;

  @override
  Widget build(BuildContext context) {
    final row = widget.selectedRow;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            row?.cycleLabel ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground),
                          ),
                          if (row?.isActive == true) ...[
                            const SizedBox(width: 8),
                            ActiveBadge(l10n: widget.l10n),
                          ],
                        ],
                      ),
                      if (row != null)
                        Text(
                          '${row.fromDate.toCompanyDate(widget.locale)} – ${row.toDate.toCompanyDate(widget.locale)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.mutedForeground),
                        ),
                    ],
                  ),
                ),
                _buildConfigWidget(),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.loading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.detailState == null || widget.detailState!.isEmpty) {
      return Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 40, color: AppTheme.mutedForeground.withAlpha(102)),
              const SizedBox(height: 12),
              Text(widget.l10n.analysisNoData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.mutedForeground, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    if (_viewMode == DetailViewMode.byCategory) {
      return CategoryBarChart(
        key: const ValueKey('byCategory'),
        items: widget.detailState!.byCategory,
        locale: widget.locale,
        currency: widget.currency,
        cycleId: widget.cycleId,
        onDrillThrough: (cycleId, alias) =>
            widget.onDrillThrough(cycleId, categoryAlias: alias),
      );
    }
    if (_viewMode == DetailViewMode.byEmployee) {
      return EmployeeBarChart(
        key: const ValueKey('byEmployee'),
        items: widget.detailState!.byEmployee,
        locale: widget.locale,
        currency: widget.currency,
        cycleId: widget.cycleId,
        onDrillThrough: (cycleId, employeeId) =>
            widget.onDrillThrough(cycleId, employeeId: employeeId),
      );
    }
    return PivotTable(
      key: const ValueKey('pivot'),
      state: widget.detailState!,
      locale: widget.locale,
      currency: widget.currency,
      cycleId: widget.cycleId,
      l10n: widget.l10n,
      onDrillThrough: widget.onDrillThrough,
    );
  }

  Widget _buildConfigWidget() {
    final canExport = widget.detailState != null;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: IntrinsicHeight(
          child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toggle(
              icon: Icons.bar_chart,
              label: widget.isMobile ? null : widget.l10n.byCategory,
              selected: _viewMode == DetailViewMode.byCategory,
              onTap: () =>
                  setState(() => _viewMode = DetailViewMode.byCategory),
            ),
            _toggle(
              icon: Icons.people,
              label: widget.isMobile ? null : widget.l10n.byEmployee,
              selected: _viewMode == DetailViewMode.byEmployee,
              onTap: () =>
                  setState(() => _viewMode = DetailViewMode.byEmployee),
            ),
            _toggle(
              icon: Icons.table_rows,
              label: null,
              selected: _viewMode == DetailViewMode.pivotTable,
              onTap: () =>
                  setState(() => _viewMode = DetailViewMode.pivotTable),
            ),
            Container(width: 1, color: AppTheme.border),
            InkWell(
              onTap: canExport ? widget.onExport : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download,
                        size: 14,
                        color: canExport
                            ? AppTheme.foreground
                            : AppTheme.mutedForeground),
                    const SizedBox(width: 6),
                    Text(widget.l10n.export,
                        style: TextStyle(
                            fontSize: 12,
                            color: canExport
                                ? AppTheme.foreground
                                : AppTheme.mutedForeground)),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String? label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label != null ? 8 : 6, vertical: 6),
        decoration: selected
            ? BoxDecoration(color: AppTheme.primary.withAlpha(20))
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color:
                    selected ? AppTheme.primary : AppTheme.mutedForeground),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.mutedForeground)),
            ],
          ],
        ),
      ),
    );
  }
}
