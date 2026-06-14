import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/format_utils.dart';
import 'spend_overview_breakdown.dart';

/// Spend Overview (§6.5) — a hero card showing Approved Spend for the last
/// closed cycle: icon, large amount, "Approved Spend · {cycle}" subtitle, and
/// (when there is spend) a "View more" link plus the By Employee / By Category
/// breakdown.
///
/// The breakdown is collapsed by default — the by-employee view grows one bar
/// per employee, which would otherwise push the Awaiting Payment card
/// off-screen. A chevron in the card's top-trailing corner (top-left under RTL)
/// expands/collapses it; the hero amount stays visible.
///
/// In [preview] mode (State A) it shows a static zero hero and skips the fetch.
class SpendOverviewCard extends ConsumerStatefulWidget {
  const SpendOverviewCard({super.key, this.preview = false});

  final bool preview;

  @override
  ConsumerState<SpendOverviewCard> createState() => _SpendOverviewCardState();
}

class _SpendOverviewCardState extends ConsumerState<SpendOverviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;

    final spend = widget.preview
        ? null
        : ref.watch(lastClosedCycleSpendProvider).asData?.value;
    final total = spend?.total ?? 0;
    final hasSpend = !widget.preview && total > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hero(
              context,
              l10n,
              locale,
              currencyCode,
              total: total,
              cycleLabel: spend?.cycleLabel,
              hasSpend: hasSpend,
            ),
            if (hasSpend)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: AlignmentDirectional.topStart,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.border),
                          const SizedBox(height: 12),
                          SpendOverviewBreakdown(
                            rows: spend!.rows,
                            locale: locale,
                            currencyCode: currencyCode,
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    String? currencyCode, {
    required double total,
    required String? cycleLabel,
    required bool hasSpend,
  }) {
    final amountText = currencyCode != null
        ? total.toCurrency(locale, currencyCode)
        : total.toFormattedNumber(locale);
    const subtitleStyle =
        TextStyle(fontSize: 13, color: AppTheme.mutedForeground);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTheme.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.trending_up, size: 22, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 2),
              // Separate runs so a mixed-direction label + cycle label (e.g.
              // Hebrew title + "March 2026") doesn't scramble under RTL bidi.
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.managerDashboardApprovedSpend,
                      style: subtitleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cycleLabel != null && cycleLabel.isNotEmpty) ...[
                    const Text(' · ', style: subtitleStyle),
                    Text(cycleLabel, style: subtitleStyle),
                  ],
                ],
              ),
              if (hasSpend) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.managerAnalysis),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.viewMore,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward,
                              size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Top-trailing chevron (top-left under RTL) expands/collapses the
        // breakdown — replaces the old in-breakdown "show details" text toggle.
        if (hasSpend)
          IconButton(
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.primary,
            ),
            tooltip: _expanded
                ? l10n.hideSpendBreakdown
                : l10n.showSpendBreakdown,
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}
