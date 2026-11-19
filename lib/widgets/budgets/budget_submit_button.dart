import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// "Submit {amount} for approval" - by the holder, or by a manager on the
/// holder's behalf (FS-1025 #4). The arrow points forward in reading
/// direction: `arrow_forward` mirrors in Hebrew (FS-1025 #9). Full width on
/// mobile, end-aligned on desktop.
class BudgetSubmitButton extends StatelessWidget {
  const BudgetSubmitButton({
    super.key,
    required this.amountText,
    required this.isBusy,
    required this.onPressed,
    this.variant = AppButtonVariant.success,
    this.bare = false,
  });

  final String amountText;
  final bool isBusy;

  /// Null = disabled (e.g. a line breaks the budget policy).
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Inside a Wrap beside Approve: no full-width / end alignment of its own.
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final button = AppButton(
      label: '${l10n.budgetsSubmitPrefix} $amountText ${l10n.budgetsSubmitSuffix}',
      variant: variant,
      icon: Icons.arrow_forward,
      isLoading: isBusy,
      onPressed: isBusy ? null : onPressed,
    );
    if (bare) return button;
    return context.isMobile
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: AlignmentDirectional.centerEnd, child: button);
  }
}
