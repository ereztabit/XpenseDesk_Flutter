import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/menu_items.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  /// Shows a Terms of Service link beside the copyright line. Used on screens
  /// with no navigation menu (e.g. the login screen) where the menu's legal
  /// links are otherwise unreachable. Opens the public marketing-site Terms.
  final bool showTermsLink;

  const AppFooter({super.key, this.showTermsLink = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final year = DateTime.now().year;

    // Single-line footer. On authenticated screens Privacy/Terms live in the
    // navigation menu, so the footer is just copyright. On menu-less screens
    // (login), showTermsLink surfaces a direct Terms link.
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            '© $year ${l10n.appName}. ${l10n.allRightsReserved}.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (showTermsLink) ...[
            Text(
              '·',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            GestureDetector(
              onTap: MenuItems.launchTerms,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  l10n.termsOfService,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
