import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';

/// Modal confirmation dialog for deleting an expense.
///
/// Shows title, warning body, Cancel and Delete buttons.
/// On Delete: calls the API, invalidates the expense provider, and pops.
class DeleteExpenseDialog extends ConsumerStatefulWidget {
  final String expenseId;

  const DeleteExpenseDialog({super.key, required this.expenseId});

  /// Show the dialog and return true if the expense was deleted.
  static Future<bool> show(BuildContext context, String expenseId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteExpenseDialog(expenseId: expenseId),
    );
    return result ?? false;
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

      // Refresh the expense list
      ref.invalidate(expenseSearchProvider);

      if (mounted) Navigator.of(context).pop(true);
    } on ExpenseException catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        l10n.deleteExpenseBody,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.mutedForeground,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.destructive,
          ),
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
