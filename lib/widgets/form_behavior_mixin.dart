import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/navigation_guard_provider.dart';
import 'app_button.dart';

/// Mixin that provides reusable form behavior:
/// - Unsaved changes tracking
/// - Navigation guard with confirmation dialog
/// - Validation mode management
mixin FormBehaviorMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // Cached notifier reference — avoids any context/ProviderScope lookup in
  // dispose(), where the element is already deactivated and ancestor lookups
  // throw "Looking up a deactivated widget's ancestor is unsafe".
  NavigationGuardNotifier? _guardNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cache the notifier here while the context is still valid.
      _guardNotifier = ref.read(navigationGuardProvider.notifier);
      _guardNotifier!.setGuard(() async => confirmDiscard());
    });
  }

  @override
  void dispose() {
    // Use the cached reference — no context/ProviderScope lookup needed.
    _guardNotifier?.setGuard(null);
    super.dispose();
  }
  /// Override this getter to indicate if the form has unsaved changes
  bool get hasUnsavedChanges;

  /// Show dialog to confirm navigation with unsaved changes
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

  /// Handle back button press with unsaved changes check
  Future<void> handleBackNavigation(String route) async {
    if (hasUnsavedChanges) {
      final shouldDiscard = await confirmDiscard();
      if (shouldDiscard && mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  /// Wrap your Scaffold with this to intercept system back button
  Widget buildWithNavigationGuard({required Widget child}) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await confirmDiscard();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

/// Widget for building a field label with optional required indicator
class FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const FieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
