import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final year = DateTime.now().year;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.muted.withValues(alpha: 0.3),
        border: const Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            // Stack vertically on mobile
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Legal Links
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to privacy policy
                      },
                      child: Text(l10n.privacyPolicy),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to terms of service
                      },
                      child: Text(l10n.termsOfService),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Copyright
                Text(
                  '© $year ${l10n.appName}. ${l10n.allRightsReserved}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }
          
          // Desktop layout - side by side
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Copyright
              Text(
                '© $year ${l10n.appName}. ${l10n.allRightsReserved}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Legal Links
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      // Navigate to privacy policy
                    },
                    child: Text(l10n.privacyPolicy),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Navigate to terms of service
                    },
                    child: Text(l10n.termsOfService),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
