import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/expense_sheet_status.dart';
import '../../utils/budget_utils.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../sheet_export/sheet_export_actions.dart';
import 'budget_awaiting_chip.dart';

/// The budget page's "Back" row. Pop keeps the list as left; a deep link
/// opens the target. On mobile an approved budget's PDF / Excel downloads
/// sit at its end, so the header card starts higher (FS-1025 #12) - or an
/// Awaiting budget's banner (#21); desktop keeps both in place.
class BudgetBackRow extends StatelessWidget {
  const BudgetBackRow({
    super.key,
    required this.budget,
    required this.email,
    required this.isManager,
    required this.onDeepLinkBack,
    this.sheet,
  });

  final Budget budget;
  final String? email;
  final bool isManager;

  /// The screen's guarded navigation to [budgetBackTarget].
  final ValueChanged<String> onDeepLinkBack;

  /// The budget's sheet, once loaded - an Awaiting one puts its banner here.
  final ExpenseSheetDetail? sheet;

  /// Mobile, Awaiting approval: the banner sits in this row (FS-1025 #21), so
  /// the page leaves its own strip out.
  static bool showsAwaiting(BuildContext context, ExpenseSheetDetail? sheet) =>
      context.isMobile && sheet?.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final back = AppButton(
      label: l10n.budgetsBack,
      variant: AppButtonVariant.ghost,
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).canPop()
          ? Navigator.of(context).pop()
          : onDeepLinkBack(budgetBackTarget(budget, email: email, isManager: isManager)),
    );
    final Widget? trailing = context.isMobile && budgetIsApproved(budget)
        ? SheetExportActions(sheetId: budget.budgetId, inRow: true)
        : showsAwaiting(context, sheet)
            ? BudgetAwaitingChip(sheet: sheet!)
            : null;
    return Row(
      children: [
        back,
        // Flexible: a large text scale shrinks the trailing part, never overflows.
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: trailing)),
        ],
      ],
    );
  }
}
