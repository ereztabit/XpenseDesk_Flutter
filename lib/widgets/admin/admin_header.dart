import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/responsive_utils.dart';
import '../action_icon_button.dart';
import '../app_button.dart';
import '../language_switcher.dart';

/// Top bar of the admin shell.
///
/// Deliberately **not** a flag on [AppHeader]: that widget bakes in the user
/// menu, the cycle indicator and company context, none of which exist for a
/// platform admin. What is left is branding, the language picker (the admin
/// panel is fully localized like the rest of the product) and a disconnect —
/// which lives here because there is no user menu to hold it.
class AdminHeader extends ConsumerStatefulWidget {
  const AdminHeader({super.key});

  @override
  ConsumerState<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends ConsumerState<AdminHeader> {
  bool _isDisconnecting = false;

  /// Real disconnect: revoke the session server-side, drop every locally cached
  /// admin provider and the stored token, then land on login. A failed logout
  /// call must still clear local state — [AuthService.logout] swallows API
  /// errors for exactly that reason — so the user is never stuck in a shell
  /// they think they left.
  Future<void> _disconnect() async {
    if (_isDisconnecting) return;
    setState(() => _isDisconnecting = true);

    try {
      await ref.read(authServiceProvider).logout();
    } finally {
      // The stored token is already gone (AuthService.logout clears it even
      // when the API call fails). What is left is in-memory state, which only
      // exists while this widget is still in the tree.
      if (mounted) {
        for (final provider in adminCachedProviders) {
          ref.invalidate(provider);
        }
        ref.read(userInfoProvider.notifier).logout();

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

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
            // Two groups with the free space between them. Only ONE flexible
            // child (the trailing group), so the logo can shrink into whatever
            // is left instead of overflowing. A `Spacer` here would compete
            // with that Flexible for the free space and shrink the logo even
            // when it fits.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The full-width button is ~117px. Together with the
                    // language picker and the 136px-wide logo that overflows a
                    // 320px viewport, so narrow drops to icon-only.
                    if (context.isNarrow)
                      ActionIconButton(
                        icon: Icons.logout,
                        tooltip: l10n.adminDisconnect,
                        color: AppTheme.foreground,
                        onPressed: _disconnect,
                      )
                    else
                      AppButton(
                        label: l10n.adminDisconnect,
                        variant: AppButtonVariant.normal,
                        icon: Icons.logout,
                        dense: true,
                        // Not `isLoading`: AppButton's spinner is white, which
                        // is invisible on the `normal` variant's light
                        // background. Disabled is the in-flight affordance.
                        onPressed: _isDisconnecting ? null : _disconnect,
                      ),
                    const SizedBox(width: 8),
                    // Always visible — unlike AppHeader, the admin shell has no
                    // mobile menu sheet to hold the picker.
                    const LanguageSwitcher(),
                  ],
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMobile) ...[
                        Text(
                          l10n.adminShellTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Image.asset(
                          'assets/images/xpensedesk-main-logo-trans.png',
                          height: isMobile ? 24 : 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
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
