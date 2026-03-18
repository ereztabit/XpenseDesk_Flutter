import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_guard_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import 'desktop_menu.dart';
import '../../models/menu_items.dart';
import 'mobile_menu_sheet.dart';
import '../language_switcher.dart';
import '../expenses/receipt_analyzer_dialog.dart';
import '../cycle/cycle_compact_badge.dart';
import '../../providers/cycle_provider.dart';

/// AppHeader - Sticky top bar with logo and user menu
///
/// Layout: Logo (left) | Language Switcher + Avatar Menu (right)
/// Role-based menu: Manager sees all options, Employee sees limited options
/// Language Switcher: Always visible in header, left of avatar/hamburger button
class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _cycleOverlayEntry;
  final GlobalKey _avatarKey = GlobalKey();
  final GlobalKey _cyclePillKey = GlobalKey();
  bool _isMenuOpen = false;

  /// Check if user is a manager
  bool _isManager(int roleId) => roleId == 1;

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) return;

    if (context.isMobile) {
      _openMobileMenu();
    } else {
      _openDesktopMenu();
    }
  }

  void _openMobileMenu() {
    // Push as a proper Navigator route so any PopupMenuButton opened from
    // within the sheet will be routed above it in the Navigator stack.
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    setState(() => _isMenuOpen = true);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, _) => MobileMenuSheet(
          onClose: _closeMenu,
          currentRoute: currentRoute,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openDesktopMenu() {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) return;

    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    _overlayEntry = OverlayEntry(
      builder: (context) => DesktopMenu(
        offset: offset,
        avatarSize: size,
        userInfo: userInfo,
        isManager: _isManager(userInfo.roleId),
        onClose: _closeMenu,
        onMenuItemSelected: _handleMenuItemSelected,
        currentRoute: currentRoute,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isMenuOpen = false);
  }

  void _handleMenuItemSelected(String value) async {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) return;

    _closeMenu();

    // Check navigation guard — same as logo tap — before any menu navigation.
    // contact-support and logout are exempt (support opens external; logout is intentional).
    if (value != 'contact-support' && value != 'logout') {
      final guard = ref.read(navigationGuardProvider);
      if (guard != null) {
        final canLeave = await guard();
        if (!canLeave || !mounted) return;
      }
    }

    switch (value) {
      case 'profile':
        final role = _isManager(userInfo.roleId) ? 'manager' : 'employee';
        if (mounted) Navigator.pushNamed(context, '/$role/profile');
        break;
      case 'expenses-analysis':
        if (mounted) Navigator.pushNamed(context, '/manager/history');
        break;
      case 'expenses-detail-report':
        final reportRoute = _isManager(userInfo.roleId)
            ? '/manager/history/report'
            : '/employee/history/report';
        if (mounted) Navigator.pushNamed(context, reportRoute);
        break;
      case 'company-config':
        if (mounted) Navigator.pushNamed(context, '/manager/company-config');
        break;
      case 'user-management':
        if (mounted) Navigator.pushNamed(context, '/manager/users');
        break;
      case 'receipt-analyzer':
        if (mounted) ReceiptAnalyzerDialog.show(context);
        break;
      case 'contact-support':
        final t = AppLocalizations.of(context)!;
        await MenuItems.launchContactSupport(userInfo, t);
        break;
      case 'logout':
        ref.read(userInfoProvider.notifier).logout();
        await ref.read(authServiceProvider).logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
        break;
    }
  }

  void _toggleCyclePopover() {
    if (_cycleOverlayEntry != null) {
      _closeCyclePopover();
    } else {
      _openCyclePopover();
    }
  }

  void _openCyclePopover() {
    final renderBox =
        _cyclePillKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final pillSize = renderBox.size;

    _cycleOverlayEntry = OverlayEntry(
      builder: (ctx) {
        const badgeWidth = 220.0;
        final screenWidth = MediaQuery.sizeOf(ctx).width;
        final left = (offset.dx + pillSize.width / 2 - badgeWidth / 2)
            .clamp(8.0, screenWidth - badgeWidth - 8);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeCyclePopover,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: offset.dy + pillSize.height + 8,
              left: left,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const CycleCompactBadge(),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_cycleOverlayEntry!);
    setState(() {});
  }

  void _closeCyclePopover() {
    _cycleOverlayEntry?.remove();
    _cycleOverlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _closeMenu();
    _closeCyclePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);
    final cycle = ref.watch(cycleContextProvider);
    final isMobile = context.isMobile;

    // This widget should only be used on authenticated pages
    if (userInfo == null) {
      return const SizedBox.shrink();
    }

    final initials = MenuItems.getInitials(userInfo.fullName, userInfo.email);

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.containerMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Desktop: cycle badge centered in the header (non-interactive)
                if (!isMobile && cycle != null)
                  const IgnorePointer(child: CycleCompactBadge()),
                Row(
              children: [
                // Menu Button - Hamburger on mobile, Avatar on desktop
                if (isMobile)
                  // Mobile: Hamburger icon
                  GestureDetector(
                    key: _avatarKey,
                    onTap: _toggleMenu,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isMenuOpen
                              ? AppTheme.muted
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.menu,
                          size: 24,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                  )
                else
                  // Desktop: Avatar Button
                  GestureDetector(
                    key: _avatarKey,
                    onTap: _toggleMenu,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, // h-9
                        height: 36, // w-9
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: _isMenuOpen
                              ? Border.all(
                                  color: AppTheme.primary.withAlpha(51),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            width: 32, // h-8
                            height: 32, // w-8
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(
                                25,
                              ), // bg-primary/10
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppTheme.primary, // text-primary
                                  fontSize: 12, // text-xs
                                  fontWeight: FontWeight.w600, // font-semibold
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Mobile: cycle pill — sits right beside the hamburger icon
                if (isMobile && cycle != null) ...[
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      key: _cyclePillKey,
                      onTap: _toggleCyclePopover,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _cycleOverlayEntry != null
                              ? AppTheme.primary.withAlpha(51)
                              : AppTheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${cycle.daysRemaining} ${l10n.cycleDays}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Language Switcher — desktop only; mobile shows it in the slide-out menu
                if (!isMobile) const LanguageSwitcher(),

                // Spacer
                const Spacer(),

                // Logo
                GestureDetector(
                  onTap: () async {
                    final guard = ref.read(navigationGuardProvider);
                    final canLeave = guard != null ? await guard() : true;
                    if (!context.mounted || !canLeave) {
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: isMobile ? 24 : 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
