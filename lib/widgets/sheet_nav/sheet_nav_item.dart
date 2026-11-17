import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../theme/app_theme.dart';
import 'sheet_nav_coming_soon_tag.dart';
import 'sheet_nav_count_pill.dart';
import 'sheet_nav_item_icon.dart';

/// One pill of the sheet-type bar (a type at level 1, a page at level 2).
///
/// Desktop: icon + label (+ [sublabel] under the label) + badge in a row, 44
/// tall. [stacked] (mobile): icon with a corner badge over a centred label of up
/// to two lines (+ [sublabel]), 64 tall. The active look (white pill) is drawn
/// by the track's sliding indicator, so this widget only colours its content.
/// [onTap] null = not clickable (coming soon, or the active page).
class SheetNavItem extends StatefulWidget {
  const SheetNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    this.sublabel,
    this.count = 0,
    this.alert = false,
    this.active = false,
    this.comingSoon = false,
    this.stacked = false,
    this.maxLabelWidth,
    this.onTap,
  });

  /// Icon data, or null to show [dotColor]'s balance dot (budgets).
  final IconData? icon;
  final String label;
  final Color accent;
  final Widget? sublabel;
  final int count;
  final bool alert;
  final bool active;
  final bool comingSoon;
  final bool stacked;

  /// Caps free-text labels (budget names). Desktop ellipsis + tooltip; mobile
  /// two lines within the width.
  final double? maxLabelWidth;
  final VoidCallback? onTap;

  @override
  State<SheetNavItem> createState() => _SheetNavItemState();
}

class _SheetNavItemState extends State<SheetNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final interactive = w.onTap != null;
    final fg = w.active || (_hovered && interactive)
        ? AppTheme.foreground
        : AppTheme.mutedForeground;
    final weight = w.active ? FontWeight.w600 : FontWeight.w500;

    final icon = SheetNavItemIcon(
      icon: w.icon,
      color: w.active ? w.accent : fg,
      dotColor: w.alert ? AppTheme.destructive : AppTheme.success,
      compact: w.stacked,
      badge: w.stacked && w.count > 0
          ? SheetNavCountPill(count: w.count, alert: w.alert, compact: true)
          : null,
    );

    Widget label = Text(
      w.label,
      // Free-text names (budgets) take their own direction, so an English name
      // on the Hebrew screen gets its ellipsis at its end, not its start.
      textDirection: w.maxLabelWidth == null
          ? null
          : (Bidi.detectRtlDirectionality(w.label)
                ? TextDirection.rtl
                : TextDirection.ltr),
      maxLines: w.stacked ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      softWrap: w.stacked,
      textAlign: w.stacked ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: w.stacked ? 12 : 14,
        height: w.stacked ? 1.05 : 1.2,
        fontWeight: weight,
        color: fg,
      ),
    );
    if (w.maxLabelWidth != null) {
      label = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w.maxLabelWidth!),
        child: label,
      );
    }

    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: w.stacked
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Flexible(child: label),
        ?w.sublabel,
        if (w.comingSoon) ...[
          const SizedBox(height: 2),
          const SheetNavComingSoonTag(),
        ],
      ],
    );

    final content = w.stacked
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 3),
              Flexible(child: texts),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(child: texts),
              if (w.count > 0) ...[
                const SizedBox(width: 8),
                SheetNavCountPill(count: w.count, alert: w.alert),
              ],
            ],
          );

    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: w.stacked ? 64 : 44,
      padding: EdgeInsets.symmetric(horizontal: w.stacked ? 4 : 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hovered && interactive && !w.active
            ? AppTheme.card.withAlpha(153)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );

    if (w.maxLabelWidth != null) {
      pill = Tooltip(
        message: w.label,
        waitDuration: const Duration(milliseconds: 500),
        child: pill,
      );
    }

    return Semantics(
      button: true,
      enabled: interactive || w.active,
      selected: w.active,
      child: MouseRegion(
        cursor: interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: w.onTap,
          child: pill,
        ),
      ),
    );
  }
}
