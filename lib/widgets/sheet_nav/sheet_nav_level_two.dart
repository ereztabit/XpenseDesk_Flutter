import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/sheet_nav.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/sheet_nav_display_utils.dart';
import 'sheet_nav_back_button.dart';
import 'sheet_nav_balance.dart';
import 'sheet_nav_caption.dart';
import 'sheet_nav_item.dart';
import 'sheet_nav_scroll_row.dart';
import 'sheet_nav_track.dart';

/// Level 2 of the sheet-type bar: the pages of one type.
///
/// Desktop: [Back] [centred group: caption + pills] [Back-sized spacer], so the
/// group is centred on the screen and only the group shrinks and scrolls.
/// Mobile ([stacked]): icon-only Back + the row; up to 3 pages share the width,
/// 4+ scroll. [onBack] null = single type, no Back and no spacer.
class SheetNavLevelTwo extends ConsumerStatefulWidget {
  const SheetNavLevelTwo({
    super.key,
    required this.section,
    required this.activeRoute,
    required this.onNavigate,
    required this.stacked,
    this.onBack,
    this.currentPath,
  });

  final SheetNavSection section;
  final String activeRoute;

  /// The page's own path when it differs from [activeRoute] (a Budgets page
  /// that highlights "All budgets"); null = the same.
  final String? currentPath;
  final ValueChanged<SheetNavPage> onNavigate;
  final bool stacked;
  final VoidCallback? onBack;

  @override
  ConsumerState<SheetNavLevelTwo> createState() => _SheetNavLevelTwoState();
}

class _SheetNavLevelTwoState extends ConsumerState<SheetNavLevelTwo> {
  static const _backZone = 120.0;
  static const _manyPages = 4;
  final _keys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currency = ref.watch(userInfoProvider)?.currencyCode ?? 'ILS';
    final section = widget.section;
    final pages = section.pages;
    final stacked = widget.stacked;
    final activeIndex = pages.indexWhere((p) => p.route == widget.activeRoute);
    final activeKey = activeIndex < 0
        ? null
        : _keyFor(pages[activeIndex].route);
    final many = pages.length >= _manyPages;

    final items = [
      for (final p in pages)
        SheetNavItem(
          key: _keyFor(p.route),
          icon: p.icon,
          label: p.caption(l10n),
          accent: section.type.accent,
          count: p.count,
          alert: p.alert || p.isBelowZero,
          active: p.route == widget.activeRoute,
          stacked: stacked,
          maxLabelWidth: p.kind == SheetNavPageKind.budget
              ? (stacked ? 120 : 180)
              : null,
          sublabel: p.balance == null
              ? null
              : SheetNavBalance(
                  text: p.balance!.toWholeCurrency(locale, currency),
                  negative: p.isBelowZero,
                  stacked: stacked,
                ),
          // Highlighted is not the same as "here": on the budget list or
          // someone else's budget "All budgets" is active but still opens B1.
          onTap: p.route == (widget.currentPath ?? widget.activeRoute)
              ? null
              : () => widget.onNavigate(p),
        ),
    ];

    final scrolls = !stacked || many;
    final track = SheetNavTrack(
      accent: section.type.accent,
      activeIndex: activeIndex < 0 ? null : activeIndex,
      expand: !scrolls,
      minChildWidth: stacked ? 88 : null,
      children: items,
    );
    final row = scrolls
        ? SheetNavScrollRow(activeKey: activeKey, child: track)
        : track;

    final group = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: stacked
          ? row
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetNavCaption(type: section.type),
                Flexible(child: row),
              ],
            ),
    );

    if (stacked) {
      return Row(
        children: [
          if (widget.onBack != null) ...[
            SheetNavBackButton(onTap: widget.onBack!, showLabel: false),
            const SizedBox(width: 8),
          ],
          Expanded(child: group),
        ],
      );
    }
    if (widget.onBack == null) return Center(child: group);
    return Row(
      children: [
        SizedBox(
          width: _backZone,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SheetNavBackButton(onTap: widget.onBack!),
          ),
        ),
        Expanded(child: Center(child: group)),
        const SizedBox(width: _backZone),
      ],
    );
  }

  GlobalKey _keyFor(String route) => _keys.putIfAbsent(route, GlobalKey.new);
}
