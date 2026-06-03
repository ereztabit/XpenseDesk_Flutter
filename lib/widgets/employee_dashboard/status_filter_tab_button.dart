import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// One pill / tab button in a status filter tab row (SheetReviewFilterTabs).
///
/// Mobile = full-radius pill, equal-width flex.
/// Desktop = top-rounded corners (first/last only), butting onto the table
/// card below; active tab raises one z-layer via background tone shift.
class StatusFilterTabButton extends StatelessWidget {
  const StatusFilterTabButton({
    super.key,
    required this.label,
    required this.count,
    required this.total,
    required this.currencyCode,
    required this.companyLocale,
    required this.tone,
    required this.isActive,
    required this.isMobile,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final int count;
  final double? total;
  final String? currencyCode;
  final String companyLocale;
  final Color tone;
  final bool isActive;
  final bool isMobile;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? tone : AppTheme.muted;
    final fg = isActive ? Colors.white : AppTheme.foreground;
    final chipBg =
        isActive ? Colors.white.withAlpha(51) : AppTheme.background;
    final chipFg = isActive ? Colors.white : AppTheme.mutedForeground;

    BorderRadius radius;
    if (isMobile) {
      radius = BorderRadius.circular(999);
    } else {
      radius = BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 12 : 0),
        topRight: Radius.circular(isLast ? 12 : 0),
      );
    }

    final totalText = (total != null && currencyCode != null)
        ? total!.toCurrency(companyLocale, currencyCode!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: chipFg,
                  ),
                ),
              ),
              if (!isMobile && totalText != null) ...[
                const SizedBox(width: 8),
                Text(
                  '· $totalText',
                  style: TextStyle(fontSize: 11, color: fg.withAlpha(204)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
