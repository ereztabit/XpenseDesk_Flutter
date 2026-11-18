import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../services/budget_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_copy_utils.dart';
import '../../utils/budget_utils.dart';
import '../app_button.dart';
import 'budget_header_actions.dart';

/// FS-1013 PC-2 - the budget list's row menu (UX hand-off section 2.2): "Submit
/// for approval" (Draft / Returned, on the holder's behalf) and "Delete" with
/// its confirm. Same `PopupMenuButton` as the user list's row menu. Hidden
/// once the budget is approved (the list never shows one).
class BudgetRowMenu extends ConsumerWidget {
  const BudgetRowMenu({super.key, required this.budget});

  final Budget budget;

  static const _edit = 'edit';
  static const _submit = 'submit';
  static const _delete = 'delete';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isManager = ref.watch(userInfoProvider)?.isManager ?? false;
    if (!budgetManagerCanChange(budget, isManager: isManager)) {
      return const SizedBox.shrink();
    }

    // 32x32 with no padding - the ActionIconButton size - so it fits the
    // table's narrow menu column without overflowing.
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.mutedForeground),
      tooltip: l10n.budgetsMenu,
      onSelected: (v) => switch (v) {
        _edit => _onEdit(context),
        _submit => _onSubmit(context, ref),
        _ => _onDelete(context, ref),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 12),
              Text(l10n.budgetsEdit),
            ],
          ),
        ),
        if (budgetCanSubmit(budget))
          PopupMenuItem(
            value: _submit,
            child: Row(
              children: [
                const Icon(Icons.send_outlined, size: 18),
                const SizedBox(width: 12),
                Text(l10n.budgetsSubmit),
              ],
            ),
          ),
        PopupMenuItem(
          value: _delete,
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppTheme.destructive),
              const SizedBox(width: 12),
              Text(l10n.budgetsDelete, style: const TextStyle(color: AppTheme.destructive)),
            ],
          ),
        ),
      ],
      ),
    );
  }

  /// FS-1013 QA: edit straight from the list - the budget page's Edit.
  Future<void> _onEdit(BuildContext context) => BudgetHeaderActions.edit(context, budget);

  Future<void> _onSubmit(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _run(context, ref, () => ref.read(budgetServiceProvider).submit(budget.budgetId),
        l10n.budgetsSubmittedToast);
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.budgetsDeleteTitle),
            content: Text('"${budget.name}" ${l10n.budgetsDeleteBody}'),
            actions: [
              AppButton(
                label: l10n.cancel,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              AppButton(
                label: l10n.budgetsDeleteConfirm,
                variant: AppButtonVariant.destructive,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await _run(context, ref, () => ref.read(budgetServiceProvider).delete(budget.budgetId),
        l10n.budgetsDeleted);
  }

  /// Runs the call, then re-reads the budgets whatever happened (the budget
  /// may have moved under us) and toasts the outcome.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() call,
    String doneMessage,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Captured before the await: the row can leave the list meanwhile.
    final container = ProviderScope.containerOf(context, listen: false);
    String? error;
    try {
      await call();
    } on BudgetException catch (e) {
      error = budgetErrorText(l10n, e.errorCode) ?? l10n.genericErrorRetry;
    } catch (_) {
      error = l10n.genericErrorRetry;
    }
    container
      ..invalidate(budgetsProvider)
      ..invalidate(myBudgetsFetchProvider)
      ..invalidate(budgetProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? doneMessage),
      duration: const Duration(seconds: 3),
    ));
  }
}
