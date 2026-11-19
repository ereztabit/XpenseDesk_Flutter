import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../action_icon_button.dart';

/// Eye by a Payments row's checkbox: opens the row's sheet (Monthly review or
/// budget page) on top of the report, so Back returns to the same spot.
class PaymentViewSheetButton extends StatelessWidget {
  const PaymentViewSheetButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionIconButton(
    icon: Icons.visibility_outlined,
    tooltip: AppLocalizations.of(context)!.paymentsViewSheetTooltip,
    color: AppTheme.primary,
    onPressed: onPressed,
  );
}
