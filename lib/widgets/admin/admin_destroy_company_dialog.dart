import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_companies_utils.dart';
import '../app_button.dart';
import '../error_alert.dart';

/// FS-1005: the typed-name confirmation in front of "Destroy company".
///
/// Non-dismissable, and Destroy stays disabled until the typed text matches the
/// company name ([AdminDestroyConfirmation]) — the same rule the server applies.
/// A failed destroy keeps the dialog open with the reason, because every failure
/// the server reports means nothing was deleted and a retry is safe.
///
/// Pops `true` only after the server confirmed the company is gone.
class AdminDestroyCompanyDialog extends ConsumerStatefulWidget {
  const AdminDestroyCompanyDialog({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  static Future<bool> show(
    BuildContext context, {
    required String companyId,
    required String companyName,
  }) async {
    final destroyed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminDestroyCompanyDialog(
        companyId: companyId,
        companyName: companyName,
      ),
    );
    return destroyed ?? false;
  }

  @override
  ConsumerState<AdminDestroyCompanyDialog> createState() =>
      _AdminDestroyCompanyDialogState();
}

class _AdminDestroyCompanyDialogState
    extends ConsumerState<AdminDestroyCompanyDialog> {
  final _nameController = TextEditingController();
  bool _isDestroying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canDestroy =>
      !_isDestroying &&
      AdminDestroyConfirmation.matches(_nameController.text, widget.companyName);

  String _messageFor(String? errorCode, AppLocalizations l10n) {
    return switch (errorCode) {
      'AdminDestroyConfirmationMismatch' => l10n.adminDestroyCompanyNameMismatch,
      'AdminCompanyNotFound' => l10n.adminDestroyCompanyNotFound,
      'DeleteCompanyTranzilaCleanupFailed' => l10n.adminDestroyCompanyBillingFailed,
      'DeleteCompanyFileCleanupFailed' => l10n.adminDestroyCompanyFilesFailed,
      _ => l10n.adminDestroyCompanyFailed,
    };
  }

  Future<void> _destroy() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isDestroying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(adminServiceProvider).destroyCompany(
            companyId: widget.companyId,
            confirmationName: _nameController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AdminException catch (e) {
      if (mounted) {
        setState(() {
          _isDestroying = false;
          _errorMessage = _messageFor(e.errorCode, l10n);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDestroying = false;
          _errorMessage = l10n.adminDestroyCompanyFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.adminDestroyCompanyTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withAlpha(25),
                border: Border.all(color: AppTheme.destructive),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.destructive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.adminDestroyCompanyWarning,
                      style: const TextStyle(color: AppTheme.destructive),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.adminDestroyCompanyTypeName),
            const SizedBox(height: 4),
            Text(
              widget.companyName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_isDestroying,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              ErrorAlert(message: _errorMessage!),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          dense: true,
          onPressed:
              _isDestroying ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: l10n.adminDestroyCompanyConfirm,
          variant: AppButtonVariant.destructive,
          dense: true,
          isLoading: _isDestroying,
          onPressed: _canDestroy ? _destroy : null,
        ),
      ],
    );
  }
}
