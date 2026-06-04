import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Centered error state for Sheet Review — shows a not-found message (the
/// server returns 404 for both missing and not-authorized) or a generic
/// error, plus a back button.
class SheetReviewErrorView extends StatelessWidget {
  const SheetReviewErrorView({super.key, required this.isNotFound});

  final bool isNotFound;

  void _back(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/dashboard');
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
            label: l10n.backToDashboard,
            variant: AppButtonVariant.normal,
            icon: Icons.arrow_back,
            onPressed: () => _back(context),
          ),
        ],
      ),
    );
  }
}
