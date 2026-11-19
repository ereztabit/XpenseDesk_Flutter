import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/budget_shake_provider.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// "Submit {amount} for approval" - by the holder, or by a manager on the
/// holder's behalf (FS-1025 #4). The arrow points forward in reading
/// direction: `arrow_forward` mirrors in Hebrew (#9). Full width on mobile,
/// end-aligned on desktop.
///
/// [blocked] (a line still needs action): the button looks disabled, and a tap
/// anyway shakes the budget's Needs action card to show why (#17).
class BudgetSubmitButton extends ConsumerWidget {
  const BudgetSubmitButton({
    super.key,
    required this.budgetId,
    required this.amountText,
    required this.isBusy,
    required this.onPressed,
    this.blocked = false,
    this.variant = AppButtonVariant.success,
    this.bare = false,
  });

  final String budgetId;
  final String amountText;
  final bool isBusy;
  final VoidCallback onPressed;
  final bool blocked;
  final AppButtonVariant variant;

  /// Inside a Wrap beside Approve: no full-width / end alignment of its own.
  final bool bare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Widget button = AppButton(
      label: '${l10n.budgetsSubmitPrefix} $amountText ${l10n.budgetsSubmitSuffix}',
      variant: variant,
      icon: Icons.arrow_forward,
      isLoading: isBusy,
      onPressed: blocked || isBusy ? null : onPressed,
    );
    if (blocked) {
      button = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(budgetNeedsActionShakeProvider(budgetId).notifier).shake(),
        child: button,
      );
    }
    if (bare) return button;
    return context.isMobile
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: AlignmentDirectional.centerEnd, child: button);
  }
}
