import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/navigation_guard_provider.dart';
import 'app_button.dart';

/// Lightweight guard mixin for onboarding step states (and any ConsumerState
/// that is NOT an authenticated screen using FormBehaviorMixin).
///
/// Registers a navigation guard so that logo taps prompt the user to confirm
/// before discarding unsaved input.
///
/// Usage:
///   class _MyStepState extends ConsumerState`<MyStep>` with StepGuardMixin {
///     @override
///     bool get hasUnsavedChanges => _controller.text.isNotEmpty;
///   }
mixin StepGuardMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // Cached to avoid context/ProviderScope lookup in dispose() where the
  // element is already deactivated and ancestor lookups are unsafe.
  NavigationGuardNotifier? _guardNotifier;

  /// Return true when the step has input the user would lose on navigation.
  bool get hasUnsavedChanges;

  Future<bool> confirmDiscard() async {
    if (!hasUnsavedChanges) return true;

    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          AppButton(
            label: l10n.keepEditing,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: l10n.leaveWithoutSaving,
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _guardNotifier = ref.read(navigationGuardProvider.notifier);
      _guardNotifier!.setGuard(() async => confirmDiscard());
    });
  }

  @override
  void dispose() {
    _guardNotifier?.setGuard(null);
    super.dispose();
  }
}
