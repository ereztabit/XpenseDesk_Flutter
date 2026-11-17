import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/sheet_nav.dart';
import '../../providers/navigation_guard_provider.dart';
import '../../providers/sheet_nav_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/instant_route.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_nav_utils.dart';
import 'sheet_nav_level_one.dart';
import 'sheet_nav_level_two.dart';

/// The sheet-type navigation bar (docs/completed/sheet-type-nav-spec.md).
///
/// Placed by a screen directly under `AppHeader`, outside the scroll view, so it
/// stays pinned. Opens at level 2 of the current page's type; Back shows level 1
/// without navigating; a type tap opens its level 2 and goes to its first page.
/// Renders nothing when the user has no bar (spec section 3).
class SheetTypeBar extends ConsumerStatefulWidget {
  const SheetTypeBar({super.key});

  @override
  ConsumerState<SheetTypeBar> createState() => _SheetTypeBarState();
}

class _SheetTypeBarState extends ConsumerState<SheetTypeBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = ref.watch(sheetNavProvider);
    if (sections == null) return const SizedBox.shrink();

    final route = sheetNavActiveRoute(
      sections,
      ModalRoute.of(context)?.settings.name ?? '',
    );
    final stacked = context.isMobile;
    final single = sections.length == 1;
    final current = sheetNavSectionFor(sections, route);
    // A type with a single page (an employee's Monthly = My expenses, or one
    // budget) has nothing to choose at level 2: show the types row with that
    // type active instead of one lone item behind a back arrow.
    // Level 2 only after the user picked a type (sheetNavShowPagesProvider):
    // every landing opens at the types row.
    final showPages = ref.watch(sheetNavShowPagesProvider);
    final open = single
        ? sections.single
        : (!showPages || (current?.pages.length ?? 0) <= 1 ? null : current);

    final Widget level = open == null || open.isComingSoon
        ? SheetNavLevelOne(
            key: const ValueKey('types'),
            sections: sections,
            activeType: current?.type,
            stacked: stacked,
            onSelect: _selectType,
          )
        : SheetNavLevelTwo(
            key: ValueKey(open.type),
            section: open,
            activeRoute: route,
            currentPath: Uri.parse(ModalRoute.of(context)?.settings.name ?? '').path,
            stacked: stacked,
            onNavigate: (p) => _go(p.route),
            onBack: single
                ? null
                : () => ref.read(sheetNavShowPagesProvider.notifier).set(false),
          );

    final noMotion = MediaQuery.of(context).disableAnimations;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      label: l10n.sheetNavLabel,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.containerMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: stacked ? 76 : 60,
                child: AnimatedSwitcher(
                  duration: noMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(rtl ? -0.03 : 0.03, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.center,
                    children: [...previous, ?current],
                  ),
                  child: level,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectType(SheetNavSection section) {
    final first = section.firstPage;
    if (first == null) return;
    final route = ModalRoute.of(context)?.settings.name ?? '';
    ref.read(sheetNavShowPagesProvider.notifier).set(true);
    if (first.route == route) return;
    _go(first.route);
  }

  /// Same semantics as the old Team / My switcher: replace the page, through the
  /// unsaved-changes guard, with no page transition (the bar stays put; only its
  /// marker animates).
  Future<void> _go(String route) async {
    final guard = ref.read(navigationGuardProvider);
    final canLeave = guard != null ? await guard() : true;
    if (!mounted || !canLeave) return;
    Navigator.of(context).pushReplacement(instantRoute(route));
  }
}
