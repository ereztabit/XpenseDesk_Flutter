import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pwa_provider.dart';
import '../../utils/pwa_utils.dart';
import 'ios_install_instructions_sheet.dart';

/// Non-visual trigger that auto-opens the iOS install drawer once per load.
///
/// Renders nothing. On iOS (and only when not already installed and not
/// previously dismissed) it presents [IosInstallInstructionsSheet] as a bottom
/// drawer after first frame. Closing it persists the dismissal so it won't
/// reappear on future loads — the "Install app" menu item still opens it
/// on demand. No-op on desktop/Android.
class IosInstallAutoPrompt extends ConsumerStatefulWidget {
  const IosInstallAutoPrompt({super.key});

  @override
  ConsumerState<IosInstallAutoPrompt> createState() =>
      _IosInstallAutoPromptState();
}

class _IosInstallAutoPromptState extends ConsumerState<IosInstallAutoPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (!mounted) return;
    if (!PwaUtils.shouldShowIosHint) return;
    if (ref.read(iosHintDismissedProvider)) return;
    if (ref.read(iosHintAutoShownProvider)) return;

    ref.read(iosHintAutoShownProvider.notifier).markShown();
    await IosInstallInstructionsSheet.show(context);
    // Closing the auto-opened drawer counts as "seen" — don't nag next load.
    if (mounted) ref.read(iosHintDismissedProvider.notifier).dismiss();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
