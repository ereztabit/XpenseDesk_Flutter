import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/sheet_nav.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_nav_display_utils.dart';
import 'sheet_nav_item.dart';
import 'sheet_nav_track.dart';

/// Level 1 of the sheet-type bar: one pill per type. Desktop: centred, pills
/// sized to their label. Mobile ([stacked]): full width, equal shares, icon over
/// a short name. A coming-soon type is shown but not clickable.
class SheetNavLevelOne extends StatelessWidget {
  const SheetNavLevelOne({
    super.key,
    required this.sections,
    required this.activeType,
    required this.onSelect,
    required this.stacked,
  });

  final List<SheetNavSection> sections;
  final SheetNavType? activeType;
  final ValueChanged<SheetNavSection> onSelect;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeIndex = sections.indexWhere((s) => s.type == activeType);

    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SheetNavTrack(
        accent: (activeType ?? SheetNavType.monthly).accent,
        activeIndex: activeIndex < 0 ? null : activeIndex,
        expand: stacked,
        children: [
          for (final s in sections)
            SheetNavItem(
              icon: s.type.icon,
              label: stacked ? s.type.shortName(l10n) : s.type.fullName(l10n),
              accent: s.type.accent,
              count: s.firstPage?.count ?? 0,
              alert: s.firstPage?.alert ?? false,
              active: s.type == activeType,
              comingSoon: s.isComingSoon,
              stacked: stacked,
              onTap: s.isComingSoon ? null : () => onSelect(s),
            ),
        ],
      ),
    );

    return stacked ? track : Center(child: track);
  }
}
