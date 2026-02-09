import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../generated/l10n/app_localizations.dart';

/// Custom avatar menu overlay - Jira-style popover
class AvatarMenu extends ConsumerStatefulWidget {
  final Offset offset;
  final Size avatarSize;
  final dynamic tokenInfo;
  final bool isManager;
  final VoidCallback onClose;
  final Function(String) onMenuItemSelected;

  const AvatarMenu({
    super.key,
    required this.offset,
    required this.avatarSize,
    required this.tokenInfo,
    required this.isManager,
    required this.onClose,
    required this.onMenuItemSelected,
  });

  @override
  ConsumerState<AvatarMenu> createState() => _AvatarMenuState();
}

class _AvatarMenuState extends ConsumerState<AvatarMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150), // duration-150
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final menuWidth = 288.0; // w-72
    final menuLeft = widget.offset.dx + widget.avatarSize.width - menuWidth;
    final menuTop = widget.offset.dy + widget.avatarSize.height + 8; // sideOffset={8}

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _handleClose();
        }
      },
      child: GestureDetector(
        onTap: _handleClose,
        behavior: HitTestBehavior.translucent,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Positioned menu
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: GestureDetector(
                  onTap: () {}, // Prevent clicks inside menu from closing it
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Material(
                      elevation: 8, // shadow-lg
                      borderRadius: BorderRadius.circular(12), // rounded-lg (--radius: 0.75rem)
                      color: AppTheme.card, // bg-popover
                      child: Container(
                        width: menuWidth,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border), // border border-border
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // User info section
                            _buildUserInfoSection(),
                            
                            // Divider
                            Container(
                              height: 1, // h-[1px]
                              width: double.infinity, // w-full
                              color: AppTheme.border, // bg-border
                            ),

                            // Menu items group
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4), // py-1
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.person_outline,
                                    label: t?.myProfile ?? 'My Profile',
                                    onTap: () => widget.onMenuItemSelected('profile'),
                                  ),

                                  if (widget.isManager) ...[
                                    _buildMenuItem(
                                      icon: Icons.history,
                                      label: t?.spendHistory ?? 'Spend History',
                                      onTap: () => widget.onMenuItemSelected('history'),
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.business,
                                      label: t?.companyConfiguration ?? 'Company Configuration',
                                      onTap: () => widget.onMenuItemSelected('company-config'),
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.people_outline,
                                      label: t?.userManagement ?? 'User Management',
                                      onTap: () => widget.onMenuItemSelected('users'),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: AppTheme.border,
                            ),

                            // Logout section
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _buildMenuItem(
                                icon: Icons.logout,
                                label: t?.logout ?? 'Logout',
                                onTap: () => widget.onMenuItemSelected('logout'),
                                isDestructive: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final initials = _getInitials(widget.tokenInfo.fullName, widget.tokenInfo.email);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), // px-5 pt-5 pb-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // items-center
        children: [
          // Avatar - h-14 w-14 mb-1
          Container(
            width: 56, // h-14
            height: 56, // w-14
            margin: const EdgeInsets.only(bottom: 4), // mb-1
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1), // bg-primary/10
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.primary, // text-primary
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.w600, // font-semibold
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4), // gap-1
          
          // Name - text-sm font-semibold text-foreground
          Text(
            widget.tokenInfo.fullName ?? widget.tokenInfo.email,
            style: const TextStyle(
              fontSize: 14, // text-sm
              fontWeight: FontWeight.w600, // font-semibold
              color: AppTheme.foreground, // text-foreground
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          
          // Email - text-xs text-muted-foreground
          Text(
            widget.tokenInfo.email,
            style: const TextStyle(
              fontSize: 12, // text-xs
              color: AppTheme.mutedForeground, // text-muted-foreground
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.muted.withOpacity(0.6), // hover:bg-muted/60
        splashColor: AppTheme.muted.withOpacity(0.4),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // px-5 py-2.5
          child: Row(
            children: [
              Icon(
                icon,
                size: 16, // h-4 w-4
                color: isDestructive ? AppTheme.mutedForeground : AppTheme.mutedForeground, // text-muted-foreground for icons
              ),
              const SizedBox(width: 12), // gap-3
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: isDestructive ? AppTheme.mutedForeground : AppTheme.foreground, // text-foreground or text-muted-foreground
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String? fullName, String email) {
    if (fullName == null || fullName.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
