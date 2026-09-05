import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// The whole-sheet CTAs (Approve / Decline). Rendered when the sheet is
/// WaitingForApproval (both buttons) or Declined (approve only — re-declining
/// a declined sheet is rejected by the server, so [onDecline] is null and the
/// decline button is omitted). The orchestrator places this inline on desktop
/// and in a sticky bottom bar on mobile — this widget just lays out the buttons.
///
/// Captions state what will happen: the approve CTA reads
/// "Approve N expenses of {amount}" — N/amount cover only the lines the server
/// will actually approve (declined lines stay declined). When nothing is
/// approvable (all lines declined) the CTA reads as a close action instead.
/// On mobile the buttons stack full-width so the descriptive labels never
/// overflow.
class SheetReviewActions extends StatelessWidget {
  const SheetReviewActions({
    super.key,
    required this.onApprove,
    required this.isBusy,
    required this.expenseCount,
    required this.amountText,
    this.onDecline,
    this.onAddExpense,
  });

  final VoidCallback onApprove;
  final VoidCallback? onDecline;

  /// FS-1004. Files a line onto this sheet on the owner's behalf, approved on
  /// entry. Sits beside the approve CTA because it is part of the same decision
  /// moment - the manager adds the receipt the employee could not, then
  /// approves. Null omits it (an Approved sheet takes no new lines).
  final VoidCallback? onAddExpense;
  final bool isBusy;

  /// Number of lines the approve will actually approve (non-declined lines).
  final int expenseCount;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    final expenseWord =
        expenseCount == 1 ? l10n.expenseWordSingular : l10n.expensesWord;
    // All-declined sheet: approving is the close path — say so instead of
    // "Approve 0 expenses".
    // approveCtaPrefix, not l10n.approve: this reads as a noun phrase ("Approve
    // 3 expenses of X" / "אישור 3 הוצאות בסך X"), and Hebrew needs the noun
    // form here where the bare button elsewhere needs the imperative.
    final approveLabel = expenseCount == 0
        ? l10n.closeSheetNothingToApprove
        : '${l10n.approveCtaPrefix} $expenseCount $expenseWord '
            '${l10n.approveOfAmountConnector} $amountText';

    final approveButton = AppButton(
      label: approveLabel,
      variant: AppButtonVariant.success,
      icon: Icons.check,
      isLoading: isBusy,
      onPressed: isBusy ? null : onApprove,
    );
    final declineButton = onDecline == null
        ? null
        : AppButton(
            label: l10n.returnSheetToUserCta,
            variant: AppButtonVariant.destructive,
            // assignment_return (a document handed back), not undo: this does
            // not reverse anything, it sends the sheet back to its owner to
            // edit. An undo arrow read as "cancel my last action".
            icon: Icons.assignment_return,
            onPressed: isBusy ? null : onDecline,
          );
    final addExpenseButton = onAddExpense == null
        ? null
        : AppButton(
            label: l10n.sheetReviewAddExpense,
            variant: AppButtonVariant.normal,
            icon: Icons.add,
            onPressed: isBusy ? null : onAddExpense,
          );

    if (isMobile) {
      // Add Expenses leads: completing the sheet comes before deciding on it.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (addExpenseButton != null) ...[
            addExpenseButton,
            const SizedBox(height: 8),
          ],
          approveButton,
          if (declineButton != null) ...[
            const SizedBox(height: 8),
            declineButton,
          ],
        ],
      );
    }

    // Wrap, not Row: three descriptive labels (the approve CTA carries a count
    // and an amount) can exceed the available width at the 768px desktop
    // breakpoint, especially in Hebrew. A Row would render an overflow stripe;
    // this drops the buttons onto a second line instead.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: [
        ?addExpenseButton,
        ?declineButton,
        approveButton,
      ],
    );
  }
}

/// Sticky bottom container for the mobile action bar — white surface, top
/// border, safe-area padding.
class SheetReviewStickyActionBar extends StatelessWidget {
  const SheetReviewStickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: child,
    );
  }
}
