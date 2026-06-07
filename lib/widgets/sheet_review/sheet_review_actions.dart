import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// The two whole-sheet CTAs (Approve / Decline). Rendered only when the sheet
/// is WaitingForApproval. The orchestrator places this inline on desktop and
/// in a sticky bottom bar on mobile — this widget just lays out the buttons.
///
/// Captions state what will happen: the approve CTA reads
/// "Approve N expenses of {amount}" and decline is reworded to "Return this
/// sheet to user to edit". On mobile the two buttons stack full-width so the
/// descriptive labels never overflow.
class SheetReviewActions extends StatelessWidget {
  const SheetReviewActions({
    super.key,
    required this.onApprove,
    required this.onDecline,
    required this.isBusy,
    required this.expenseCount,
    required this.amountText,
  });

  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final bool isBusy;
  final int expenseCount;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    final expenseWord =
        expenseCount == 1 ? l10n.expenseWordSingular : l10n.expensesWord;
    final approveLabel = '${l10n.approve} $expenseCount $expenseWord '
        '${l10n.approveOfAmountConnector} $amountText';

    final approveButton = AppButton(
      label: approveLabel,
      variant: AppButtonVariant.success,
      icon: Icons.check,
      isLoading: isBusy,
      onPressed: isBusy ? null : onApprove,
    );
    final declineButton = AppButton(
      label: l10n.returnSheetToUserCta,
      variant: AppButtonVariant.destructive,
      icon: Icons.undo,
      onPressed: isBusy ? null : onDecline,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          approveButton,
          const SizedBox(height: 8),
          declineButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        declineButton,
        const SizedBox(width: 12),
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
