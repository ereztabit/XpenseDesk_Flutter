import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/menu_items.dart';

/// Desktop menu overlay - Jira-style popover
class DesktopMenu extends ConsumerStatefulWidget {
  final Offset offset;
  final Size avatarSize;
  final dynamic userInfo;
  final bool isManager;
  final VoidCallback onClose;
  final Function(String) onMenuItemSelected;

  const DesktopMenu({
    super.key,
    required this.offset,
    required this.avatarSize,
    required this.userInfo,
    required this.isManager,
    required this.onClose,
    required this.onMenuItemSelected,
  });

  @override
  ConsumerState<DesktopMenu> createState() => _DesktopMenuState();
}

class _DesktopMenuState extends ConsumerState<DesktopMenu>
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

                            // Menu items
                            ...MenuItems.getItems(t!, widget.isManager).asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final items = MenuItems.getItems(t, widget.isManager);
                              final isLast = index == items.length - 1;
                              final isPrevItemAction = index > 0 && items[index - 1].isAction;
                              
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (index == 0)
                                    const SizedBox.shrink(),
                                  if ((item.isAction && !isPrevItemAction) || (isLast && item.isDestructive) || item.id == 'contact-support')
                                    Container(
                                      height: 1,
                                      width: double.infinity,
                                      color: AppTheme.border,
                                    ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: (index == 0 || item.isAction) ? 4 : 0,
                                    ),
                                    child: _buildMenuItem(
                                      icon: item.icon,
                                      label: item.label,
                                      onTap: () => widget.onMenuItemSelected(item.id),
                                      isAction: item.isAction,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
    final initials = MenuItems.getInitials(widget.userInfo.fullName, widget.userInfo.email);
    
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
              color: AppTheme.primary.withAlpha(25), // bg-primary/10
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
            widget.userInfo.fullName ?? widget.userInfo.email,
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
            widget.userInfo.email,
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
    bool isAction = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.muted.withAlpha(153), // hover:bg-muted/60
        splashColor: AppTheme.muted.withAlpha(102),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // px-5 py-2.5
          child: Row(
            children: [
              Icon(
                icon,
                size: 16, // h-4 w-4
                color: AppTheme.mutedForeground, // text-muted-foreground for icons
              ),
              const SizedBox(width: 12), // gap-3
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: isAction ? AppTheme.mutedForeground : AppTheme.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
