import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_items.dart';

class MobileMenuSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const MobileMenuSheet({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<MobileMenuSheet> createState() => _MobileMenuSheetState();
}

class _MobileMenuSheetState extends ConsumerState<MobileMenuSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  void _handleMenuItemSelected(String value) async {
    final tokenInfo = ref.read(tokenInfoProvider);
    final t = AppLocalizations.of(context)!;

    if (value == 'contact-support' && tokenInfo != null) {
      await MenuItems.launchContactSupport(tokenInfo, t);
    } else if (value == 'logout') {
      await _close();
      ref.read(tokenInfoProvider.notifier).logout();
      await ref.read(authServiceProvider).clearSessionToken();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
    // TODO: Add navigation for other menu items
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tokenInfo = ref.watch(tokenInfoProvider);
    final isManager = tokenInfo?.roleId == 1;

    final screenWidth = MediaQuery.of(context).size.width;
    final sheetWidth = (screenWidth * 0.75).clamp(0.0, 384.0);

    final menuItems = MenuItems.getItems(t, isManager);

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: _close,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

        // Side sheet
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: sheetWidth,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.white,
              elevation: 16,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _close,
                            iconSize: 24,
                            color: const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),

                    // User info section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                MenuItems.getInitials(
                                  tokenInfo?.fullName,
                                  tokenInfo?.email ?? '',
                                ),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // User details
                          Expanded(
                            child: MenuItems.buildUserInfo(tokenInfo, t),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Menu items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final isPrevItemAction = index > 0 && menuItems[index - 1].isAction;

                          return Column(
                            children: [
                              if ((item.isAction && !isPrevItemAction) || item.id == 'contact-support')
                                const Divider(height: 1),
                              InkWell(
                                onTap: () => _handleMenuItemSelected(item.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: AppTheme.mutedForeground,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: item.isAction
                                                ? AppTheme.mutedForeground
                                                : AppTheme.foreground,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
