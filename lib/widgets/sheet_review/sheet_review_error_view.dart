import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Centered error state for Sheet Review — shows a not-found message (the
/// server returns 404 for both missing and not-authorized) or a generic
/// error, plus a back button. [fallbackRoute] is where Back goes when there is
/// nothing to pop: Sheet Approvals for a manager, History for an employee
/// opening a read-only sheet (PC-9) - the label follows it.
class SheetReviewErrorView extends StatelessWidget {
  const SheetReviewErrorView({
    super.key,
    required this.isNotFound,
    this.fallbackRoute = '/manager-approvals',
  });

  final bool isNotFound;
  final String fallbackRoute;

  bool get _toApprovals => fallbackRoute == '/manager-approvals';

  void _back(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(
            isNotFound ? l10n.sheetNoLongerExists : l10n.errorTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _toApprovals ? l10n.backToApprovals : l10n.back,
            variant: AppButtonVariant.normal,
            icon: Icons.arrow_back,
            onPressed: () => _back(context),
          ),
        ],
      ),
    );
  }
}
