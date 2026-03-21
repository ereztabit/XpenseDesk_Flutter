import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';

class DeleteExpenseDialog extends ConsumerStatefulWidget {
  final String expenseId;

  const DeleteExpenseDialog({super.key, required this.expenseId});

  /// Shows the delete confirmation dialog.
  ///
  /// On API failure, shows an error modal with an OK button.
  /// If [onRefresh] is provided it is called after the user dismisses
  /// the error modal so the caller can refresh stale data.
  static Future<bool> show(
    BuildContext context,
    String expenseId, {
    VoidCallback? onRefresh,
  }) async {
    final result = await showDialog<({bool deleted, String? error})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteExpenseDialog(expenseId: expenseId),
    );

    if (result?.error != null && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(
            l10n.errorTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Text(
            result!.error!,
            style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      if (context.mounted) onRefresh?.call();
    }

    return result?.deleted ?? false;
  }

  @override
  ConsumerState<DeleteExpenseDialog> createState() =>
      _DeleteExpenseDialogState();
}

class _DeleteExpenseDialogState extends ConsumerState<DeleteExpenseDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.deleteExpense(widget.expenseId);
      ref.invalidate(expenseSearchProvider);
      if (mounted) Navigator.of(context).pop((deleted: true, error: null));
    } on ExpenseException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = e.errorCode == 'ExpensesDeleteExpenseCannotBeDeleted'
            ? l10n.deleteExpenseAlreadyAddressed
            : e.message.isNotEmpty
                ? e.message
                : l10n.deleteExpenseFailed;
        Navigator.of(context).pop((deleted: false, error: msg));
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context)
            .pop((deleted: false, error: l10n.deleteExpenseFailed));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.deleteExpense,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Text(
        l10n.deleteExpenseBody,
        style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () =>
                  Navigator.of(context).pop((deleted: false, error: null)),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.delete),
        ),
      ],
    );
  }
}
