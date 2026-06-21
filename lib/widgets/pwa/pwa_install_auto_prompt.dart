import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pwa_provider.dart';
import '../../utils/pwa_utils.dart';
import '../../utils/responsive_utils.dart';
import 'pwa_install_launcher.dart';

/// Non-visual trigger that auto-opens the install drawer once per load on
/// mobile. Renders nothing.
///
/// - **iOS:** opens the manual "Add to Home Screen" drawer.
/// - **Android/Chromium:** opens the native-prompt drawer (waiting for
///   `beforeinstallprompt` if it hasn't fired yet).
/// - **Desktop:** never auto-opens — the address-bar install icon and the
///   "Install app" menu item cover it without nagging.
///
/// Closing the drawer persists the dismissal so it won't reappear on future
/// loads; the menu item still opens it on demand.
class PwaInstallAutoPrompt extends ConsumerStatefulWidget {
  const PwaInstallAutoPrompt({super.key});

  @override
  ConsumerState<PwaInstallAutoPrompt> createState() =>
      _PwaInstallAutoPromptState();
}

class _PwaInstallAutoPromptState extends ConsumerState<PwaInstallAutoPrompt> {
  StreamSubscription? _availabilitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  void _maybeShow() {
    if (!mounted || !context.isMobile) return;
    if (ref.read(iosHintDismissedProvider)) return;
    if (ref.read(iosHintAutoShownProvider)) return;

    if (PwaUtils.shouldShowIosHint || PwaUtils.canPromptNativeInstall) {
      _show();
      return;
    }
    // Android: beforeinstallprompt may not have fired yet — wait for it once.
    _availabilitySub = PwaUtils.onInstallAvailable.listen((_) {
      if (mounted &&
          !ref.read(iosHintDismissedProvider) &&
          !ref.read(iosHintAutoShownProvider)) {
        _show();
      }
    });
  }

  Future<void> _show() async {
    _availabilitySub?.cancel();
    ref.read(iosHintAutoShownProvider.notifier).markShown();
    await showPwaInstallSheet(context);
    // Closing the auto-opened drawer counts as "seen" — don't nag next load.
    if (mounted) ref.read(iosHintDismissedProvider.notifier).dismiss();
  }

  @override
  void dispose() {
    _availabilitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
