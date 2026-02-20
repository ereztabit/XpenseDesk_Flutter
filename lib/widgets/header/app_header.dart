import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import 'desktop_menu.dart';
import '../../models/menu_items.dart';
import 'mobile_menu_sheet.dart';
import '../language_switcher.dart';

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
  final GlobalKey _avatarKey = GlobalKey();
  bool _isMenuOpen = false;

  /// Get dashboard route based on user role
  String _getDashboardRoute(int roleId) {
    return roleId == 1 ? '/manager/dashboard' : '/employee/dashboard';
  }

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
    _overlayEntry = OverlayEntry(
      builder: (context) => MobileMenuSheet(
        onClose: _closeMenu,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _openDesktopMenu() {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) return;

    final renderBox = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => DesktopMenu(
        offset: offset,
        avatarSize: size,
        userInfo: userInfo,
        isManager: _isManager(userInfo.roleId),
        onClose: _closeMenu,
        onMenuItemSelected: _handleMenuItemSelected,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isMenuOpen = false);
  }

  void _handleMenuItemSelected(String value) async {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) return;

    _closeMenu();

    switch (value) {
      case 'profile':
        final role = _isManager(userInfo.roleId) ? 'manager' : 'employee';
        if (mounted) Navigator.pushNamed(context, '/$role/profile');
        break;
      case 'spend-history':
        if (mounted) Navigator.pushNamed(context, '/manager/history');
        break;
      case 'company-config':
        if (mounted) Navigator.pushNamed(context, '/manager/company-config');
        break;
      case 'user-management':
        if (mounted) Navigator.pushNamed(context, '/manager/users');
        break;
      case 'contact-support':
        final t = AppLocalizations.of(context)!;
        await MenuItems.launchContactSupport(userInfo, t);
        break;
      case 'logout':
        ref.read(userInfoProvider.notifier).logout();
        await ref.read(authServiceProvider).clearSessionToken();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
        break;
    }
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
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
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
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
          constraints: const BoxConstraints(maxWidth: AppTheme.containerMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
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
                              color: AppTheme.primary.withAlpha(25), // bg-primary/10
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

                // Language Switcher
                const LanguageSwitcher(),

                // Spacer
                const Spacer(),

                // Logo
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, _getDashboardRoute(userInfo.roleId));
                  },
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: isMobile ? 24 : 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
