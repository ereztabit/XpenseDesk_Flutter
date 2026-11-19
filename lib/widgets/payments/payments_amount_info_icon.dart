import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Info icon by the Payments "Amount" header: a negative budget amount means
/// the employee is charged. Shown with budgets off too - their history stays
/// in the list - and the text says it is for budgets (FS-1025 #26).
class PaymentsAmountInfoIcon extends StatelessWidget {
  const PaymentsAmountInfoIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.paymentsNegativeAmountInfo,
      triggerMode: TooltipTriggerMode.tap, // touch: a tap, not a long press
      showDuration: const Duration(seconds: 5),
      child: const MouseRegion(
        cursor: SystemMouseCursors.help,
        // 6px around the 14px glyph: a 26px target a finger can hit.
        child: Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
