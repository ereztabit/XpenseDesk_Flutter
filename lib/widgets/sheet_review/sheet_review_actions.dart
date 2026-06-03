import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// The two whole-sheet CTAs (Approve / Decline). Rendered only when the sheet
/// is WaitingForApproval. The orchestrator places this inline on desktop and
/// in a sticky bottom bar on mobile — this widget just lays out the buttons.
class SheetReviewActions extends StatelessWidget {
  const SheetReviewActions({
    super.key,
    required this.onApprove,
    required this.onDecline,
    required this.isBusy,
  });

  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          label: l10n.declineSheet,
          variant: AppButtonVariant.destructive,
          icon: Icons.close,
          onPressed: isBusy ? null : onDecline,
        ),
        const SizedBox(width: 12),
        AppButton(
          label: l10n.approveSheet,
          variant: AppButtonVariant.success,
          icon: Icons.check,
          isLoading: isBusy,
          onPressed: isBusy ? null : onApprove,
        ),
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
