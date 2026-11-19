import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';

/// FS-1016 PC-5: "Clear stored sheet exports" in its own card under Billing
/// (Configuration tab). Confirms first; the SnackBar says how many stored
/// PDF / Excel files were deleted. The next download of each sheet rebuilds it.
class AdminClearExportsButton extends ConsumerStatefulWidget {
  const AdminClearExportsButton({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<AdminClearExportsButton> createState() => _AdminClearExportsButtonState();
}

class _AdminClearExportsButtonState extends ConsumerState<AdminClearExportsButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmChoiceDialog.show(
      context,
      title: l10n.adminClearSheetExportsTitle,
      body: l10n.adminClearSheetExportsBody,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.adminClearSheetExportsConfirm,
      confirmVariant: AppButtonVariant.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final deleted = await ref.read(adminServiceProvider).clearSheetExports(widget.companyId);
      messenger.showSnackBar(SnackBar(content: Text('${l10n.adminClearSheetExportsDone} $deleted')));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericErrorRetry)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppButton(
      label: l10n.adminClearSheetExports,
      variant: AppButtonVariant.normal,
      icon: Icons.cleaning_services_outlined,
      dense: true,
      isLoading: _busy,
      onPressed: _onPressed,
    );
  }
}
