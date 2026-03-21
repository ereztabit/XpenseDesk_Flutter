import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../models/expense_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class SpendOverviewWidget extends StatefulWidget {
  final List<ExpenseSummary> expenses;
  final String locale;
  final String? currencyCode;
  final VoidCallback? onNavigateAway;

  const SpendOverviewWidget({
    super.key,
    required this.expenses,
    required this.locale,
    this.currencyCode,
    this.onNavigateAway,
  });

  @override
  State<SpendOverviewWidget> createState() => _SpendOverviewWidgetState();
}

class _SpendOverviewWidgetState extends State<SpendOverviewWidget> {
  bool _expanded = false;
  bool _byEmployee = true;

  // ── derived data ─────────────────────────────────────────────────────────

  List<ExpenseSummary> get _approved =>
      widget.expenses.where((e) => e.expenseStatusId == 2).toList();

  double get _totalApproved =>
      _approved.fold(0.0, (sum, e) => sum + (e.amount ?? 0));

  List<_SpendItem> get _items {
    final approved = _approved;
    if (approved.isEmpty) return [];

    if (_byEmployee) {
      final Map<String, double> totals = {};
      final Map<String, String> idToName = {};
      for (final e in approved) {
        totals[e.createdByUserId] = (totals[e.createdByUserId] ?? 0) + (e.amount ?? 0);
        idToName[e.createdByUserId] = e.createdByName;
      }
      final entries = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final maxSpend = entries.isEmpty ? 1.0 : entries.first.value;
      return entries.map((entry) => _SpendItem(
        label: idToName[entry.key] ?? entry.key,
        filterKey: entry.key, // userId used for URL param
        total: entry.value,
        progress: entry.value / maxSpend.clamp(1.0, double.infinity),
      )).toList();
    } else {
      final Map<String, double> totals = {};
      for (final e in approved) {
        totals[e.categoryName] = (totals[e.categoryName] ?? 0) + (e.amount ?? 0);
      }
      final entries = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final maxSpend = entries.isEmpty ? 1.0 : entries.first.value;
      return entries.map((entry) => _SpendItem(
        label: _categoryLabel(entry.key, widget.locale),
        filterKey: entry.key, // category alias used for URL param
        total: entry.value,
        progress: entry.value / maxSpend.clamp(1.0, double.infinity),
      )).toList();
    }
  }

  String _categoryLabel(String apiValue, String locale) {
    final cat = ExpenseCategory.fromApiValue(apiValue);
    if (cat == null) return apiValue;
    return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  String _fmt(double v) {
    final code = widget.currencyCode;
    return code != null
        ? v.toCurrency(widget.locale, code)
        : v.toFormattedNumber(widget.locale);
  }

  void _openReport({String? categoryFilter, String? employeeFilter}) {
    final args = <String, String>{};
    if (categoryFilter != null) args['categories'] = categoryFilter;
    if (employeeFilter != null) args['employees'] = employeeFilter;
    Navigator.pushNamed(context, '/manager/analysis',
            arguments: args.isNotEmpty ? args : null)
        .then((_) => widget.onNavigateAway?.call());
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(l10n),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildContent(l10n) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.trending_up,
                size: 16, color: AppTheme.mutedForeground),
            const SizedBox(width: 8),
            Text(
              l10n.spendOverview,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedForeground,
              ),
            ),
            const Spacer(),
            Text(
              _fmt(_totalApproved),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final items = _items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.byEmployee,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.byCategory,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_byEmployee},
                onSelectionChanged: (s) =>
                    setState(() => _byEmployee = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12)),
                ),
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animate height + content when toggle changes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: items.isEmpty
                ? Padding(
                    key: const ValueKey('empty'),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.noApprovedExpenses,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.mutedForeground),
                      ),
                    ),
                  )
                : Column(
                    key: ValueKey(_byEmployee),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...items.map((item) => _buildItem(item)),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: 12),
                      Center(
                        child: InkWell(
                          onTap: () => _openReport(),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.viewMore,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward,
                                    size: 12, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_SpendItem item) {
    return InkWell(
      onTap: () => _byEmployee
          ? _openReport(employeeFilter: item.filterKey)
          : _openReport(categoryFilter: item.filterKey),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmt(item.total),
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 8,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendItem {
  final String label;     // translated display label
  final String filterKey; // raw API value for URL param
  final double total;
  final double progress;

  const _SpendItem({
    required this.label,
    required this.filterKey,
    required this.total,
    required this.progress,
  });
}
