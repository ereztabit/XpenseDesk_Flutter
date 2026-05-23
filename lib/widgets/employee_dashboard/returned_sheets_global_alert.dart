import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_utils.dart';
import '../app_button.dart';

/// Destructive banner shown when the employee has at least one Declined sheet
/// AND the picker isn't currently on one of them. Tapping "Review" sets the
/// picker selection to the first returned sheet. Dismissal persists across
/// the session via [dismissedReturnedAlertKeyProvider].
class ReturnedSheetsGlobalAlert extends ConsumerWidget {
  const ReturnedSheetsGlobalAlert({
    super.key,
    required this.sheets,
    required this.currentSelectionId,
  });

  final List<ExpenseSheetListItem> sheets;
  final String? currentSelectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final returned = sheets
        .where((s) =>
            s.expenseSheetStatusId == ExpenseSheetStatus.declined.id)
        .toList(growable: false);

    if (returned.isEmpty) return const SizedBox.shrink();

    final viewingReturned = currentSelectionId != null &&
        returned.any((s) => s.expenseSheetId == currentSelectionId);
    if (viewingReturned) return const SizedBox.shrink();

    final dismissedKey = ref.watch(dismissedReturnedAlertKeyProvider);
    final currentKey = SheetSelection.dismissalKey(returned);
    if (dismissedKey == currentKey) return const SizedBox.shrink();

    final count = returned.length;
    final isMobile = context.isMobile;
    final message = isMobile
        ? l10n.returnedSheetAlertShort
        : (count == 1
            ? l10n.returnedSheetAlertSingleFull
            : '$count ${l10n.returnedSheetsNeedAttention}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(13),
        border: Border.all(color: AppTheme.destructive.withAlpha(102)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppTheme.destructive,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: l10n.reviewSheet,
            variant: AppButtonVariant.destructive,
            onPressed: () {
              ref
                  .read(selectedSheetIdProvider.notifier)
                  .set(returned.first.expenseSheetId);
            },
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              tooltip: l10n.dismiss,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppTheme.destructive,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => ref
                  .read(dismissedReturnedAlertKeyProvider.notifier)
                  .dismiss(currentKey),
            ),
          ),
        ],
      ),
    );
  }
}
