import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/navigation_guard_provider.dart';

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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.leaveWithoutSaving),
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
      if (mounted) {
        ref
            .read(navigationGuardProvider.notifier)
            .setGuard(() async => confirmDiscard());
      }
    });
  }

  @override
  void dispose() {
    ref.read(navigationGuardProvider.notifier).setGuard(null);
    super.dispose();
  }
}
