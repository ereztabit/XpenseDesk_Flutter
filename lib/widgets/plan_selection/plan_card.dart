import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// A selectable plan card (Monthly or Annual).
class PlanCard extends StatefulWidget {
  const PlanCard({
    super.key,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.onTap,
    this.badgeLabel,
    this.savingsLabel,
  });

  /// Display price, e.g. "\$30"
  final String price;

  /// Display period, e.g. "/month"
  final String period;

  /// Whether this card is currently selected.
  final bool isSelected;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Optional badge text shown above the card (e.g. "Best Value").
  final String? badgeLabel;

  /// Optional savings text shown below the price (e.g. "Save 17%").
  final String? savingsLabel;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card body
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.primary
                      : _hovered
                          ? AppTheme.primary.withAlpha(102)
                          : AppTheme.border,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(51),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price + period
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.price,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),

                  // Savings label — fixed-height slot reserved on every card so
                  // cards with and without a savings line stay equal height
                  // without an IntrinsicHeight wrapper (which sub-pixel-overflows
                  // under dart2js). See trial-cancel-rollback bug.
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 20,
                    child: widget.savingsLabel != null
                        ? Text(
                            widget.savingsLabel!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.success,
                            ),
                          )
                        : null,
                  ),

                  // Selected indicator — fixed height to prevent layout shift
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 24,
                    child: AnimatedOpacity(
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.selected,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Badge (positioned above card)
            if (widget.badgeLabel != null)
              PositionedDirectional(
                top: -12,
                start: 0,
                end: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.badgeLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
