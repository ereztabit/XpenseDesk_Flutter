import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Full-width warning banner rendered below the AppHeader when the company's
/// subscriptionStatus is "PendingPayment".
///
/// The banner is intentionally non-dismissible — it persists on every
/// authenticated screen until the subscription is completed.
class PendingPaymentBanner extends StatelessWidget {
  const PendingPaymentBanner({super.key});

  static const _bgColor = Color(0xFFFFF7ED); // warm amber-50
  static const _borderColor = Color(0xFFFED7AA); // amber-200

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppTheme.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.pendingPaymentBannerMessage,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E), // amber-800 — readable on the light bg
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: null, // TODO: navigate to subscription screen (phase 2)
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.amber,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.pendingPaymentBannerAction),
          ),
        ],
      ),
    );
  }
}
