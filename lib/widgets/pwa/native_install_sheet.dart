import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/pwa_utils.dart';
import '../app_button.dart';

/// Bottom drawer for Chromium (Android Chrome/Edge, desktop Chrome/Edge).
///
/// Unlike iOS, here we can fire the browser's native install dialog ourselves —
/// the "Install" button calls [PwaUtils.promptNativeInstall] (a user gesture),
/// so the user is never stuck after dismissing Chrome's one-shot mini-infobar.
class NativeInstallSheet extends StatelessWidget {
  const NativeInstallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const NativeInstallSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.install_mobile,
                    size: 22, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.nativeInstallSheetTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.nativeInstallSheetBody,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            if (PwaUtils.canPromptNativeInstall) ...[
              // We have a captured beforeinstallprompt — fire the native dialog.
              AppButton(
                label: l10n.nativeInstallButton,
                variant: AppButtonVariant.primary,
                icon: Icons.install_mobile,
                onPressed: () {
                  // This tap is the required user gesture.
                  PwaUtils.promptNativeInstall();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: l10n.pwaInstallMaybeLater,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else ...[
              // No native prompt available (not yet fired, consumed, or a browser
              // that won't fire it) — fall back to manual browser-menu steps.
              _ManualNote(text: l10n.nativeInstallManualSteps),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.iosInstallSheetDone,
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fallback instructions shown when no native install prompt is captured.
class _ManualNote extends StatelessWidget {
  const _ManualNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.more_vert, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
