import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/budgets_provider.dart';
import '../../theme/app_theme.dart';

/// Info icon by the Payments "Amount" header: a negative budget amount means
/// the employee returns money. Hidden when the company has budgets off.
class PaymentsAmountInfoIcon extends ConsumerWidget {
  const PaymentsAmountInfoIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isPettyCashEnabledProvider)) return const SizedBox.shrink();
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
