import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final year = DateTime.now().year;

    // Single-line footer. Privacy Policy / Terms of Service now live in the
    // navigation menu (below Contact Support), so the footer is just copyright.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.muted.withValues(alpha: 0.3),
        border: const Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        '© $year ${l10n.appName}. ${l10n.allRightsReserved}.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
