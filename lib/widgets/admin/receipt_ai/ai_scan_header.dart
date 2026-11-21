import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/app_navigator.dart';
import '../../app_button.dart';
import 'ai_button_row.dart';
import 'ai_status_badge.dart';

/// Scan review header: Back, and the walk over the scan list (Previous / Next
/// unreviewed) on one line of full buttons; then merchant + amount, the review /
/// profile / model badges on one row, and company and dates.
class AiScanHeader extends StatelessWidget {
  const AiScanHeader({
    super.key,
    required this.review,
    required this.unreviewedLeft,
    required this.onPrevious,
    required this.onNext,
  });

  final AdminAiScanReview? review;
  final int unreviewedLeft;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = review;
    final (reviewLabel, reviewColor) = adminAiReviewLabel(l10n, r?.aiReviewStatusId);
    final seconds = r?.totalDurationMs == null
        ? ''
        : ' · ${(r!.totalDurationMs! / 1000).toStringAsFixed(1)} ${l10n.adminAiSeconds}';
    final back = AppButton(
      label: l10n.adminAiBackToUsage,
      variant: AppButtonVariant.ghost,
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.adminAiTab(AppRoutes.adminAiTabUsage)),
    );
    final nav = [
      AppButton(
        label: l10n.adminAiPrevious,
        variant: AppButtonVariant.normal,
        icon: Icons.arrow_back,
        onPressed: onPrevious,
      ),
      AppButton(
        label: l10n.adminAiNextUnreviewed,
        variant: AppButtonVariant.normal,
        icon: Icons.arrow_forward,
        onPressed: onNext,
      ),
    ];
    final left = Text('$unreviewedLeft ${l10n.adminAiUnreviewedLeft}', style: Theme.of(context).textTheme.bodyMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 760
              ? Row(
                  children: [
                    back,
                    const Spacer(),
                    left,
                    const SizedBox(width: 12),
                    ...[nav[0], const SizedBox(width: 8), nav[1]],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    back,
                    const SizedBox(height: 8),
                    left,
                    const SizedBox(height: 8),
                    AiButtonRow(children: nav),
                  ],
                ),
        ),
        if (r != null) ...[
          const SizedBox(height: 12),
          Text(
            // The amount as its own left-to-right run, so a Hebrew merchant
            // does not reorder "80.00 ILS".
            '${r.expense.merchant ?? '—'} · ${adminAiLtr(adminAiAmount(r.expense.amount, r.expense.currency))}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          // Status badges side by side on one row - not buttons.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AiStatusBadge(label: reviewLabel, color: reviewColor),
              AiStatusBadge(
                label: adminAiLtr(
                  '${adminAiProfileLabel(r.aiProfileId, r.aiProfileName)}'
                  '${r.aiProfileVersionNumber == null ? '' : ' · ${adminAiVersion(r.aiProfileVersionNumber)}'}',
                ),
                color: AppTheme.primary,
              ),
              AiStatusBadge(label: r.aiModel ?? l10n.adminAiModelUnknown, color: AppTheme.foreground),
            ],
          ),
          const SizedBox(height: 8),
          // Separate runs: a company name, a Hebrew caption and a date in one
          // string would be reordered by bidi.
          Wrap(
            spacing: 6,
            children: [
              for (final part in [
                r.companyName,
                '· ${l10n.adminAiExpenseDateLabel} ${adminAiDay(DateTime.tryParse(r.expense.date ?? ''))}',
                '· ${l10n.adminAiScanned} ${adminAiDateTime(r.scannedAt ?? r.createdAt)}$seconds',
              ])
                Text(part, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ],
    );
  }
}
