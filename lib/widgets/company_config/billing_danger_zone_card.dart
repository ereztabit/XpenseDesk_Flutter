import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'cancel_subscription_dialog.dart';

/// Danger Zone card — only visible when subscription is active (Story 5).
/// Contains the Cancel Subscription button that opens a confirmation dialog.
class BillingDangerZoneCard extends StatelessWidget {
  const BillingDangerZoneCard({
    super.key,
    required this.accessUntilDate,
    required this.locale,
  });

  /// The date access actually ends on cancel: the trial-end date while still in
  /// trial (the upcoming paid period never starts), otherwise the subscription
  /// end date. Computed by the caller (bug #4).
  final DateTime accessUntilDate;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              l10n.billingDangerZone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.destructive,
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.destructive.withAlpha(51),
            ),
            const SizedBox(height: 16),

            // Content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.billingCancelSubscription,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.billingCancelSubscriptionDesc} ${accessUntilDate.toMediumDate(locale)}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: l10n.billingCancelSubscription,
                  variant: AppButtonVariant.destructive,
                  onPressed: () => _showCancelDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => CancelSubscriptionDialog(
        endDate: accessUntilDate,
      ),
    );
  }
}
