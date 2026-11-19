import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../utils/budget_utils.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../sheet_export/sheet_export_actions.dart';

/// The budget page's "Back" row. Pop keeps the list as left; a deep link
/// opens the target. On mobile an approved budget's PDF / Excel downloads
/// sit at its end, so the header card starts higher (FS-1025 #12); desktop
/// keeps them in the card's corner.
class BudgetBackRow extends StatelessWidget {
  const BudgetBackRow({
    super.key,
    required this.budget,
    required this.email,
    required this.isManager,
    required this.onDeepLinkBack,
  });

  final Budget budget;
  final String? email;
  final bool isManager;

  /// The screen's guarded navigation to [budgetBackTarget].
  final ValueChanged<String> onDeepLinkBack;

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
    final downloads = context.isMobile && budgetIsApproved(budget)
        ? SheetExportActions(sheetId: budget.budgetId, inRow: true)
        : null;
    return Row(
      children: [
        back,
        if (downloads != null) ...[const Spacer(), downloads],
      ],
    );
  }
}
