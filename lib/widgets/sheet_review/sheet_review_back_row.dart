import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// Back-to-dashboard affordance + screen title at the top of Sheet Review.
///
/// Mobile: a plain arrow `IconButton` (matches the analysis screen) — compact
/// and reliably tappable in a narrow row.
/// Desktop: the labelled ghost button.
class SheetReviewBackRow extends StatelessWidget {
  const SheetReviewBackRow({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (context.isMobile) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
            tooltip: l10n.backToDashboard,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        AppButton(
          label: l10n.backToDashboard,
          variant: AppButtonVariant.ghost,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 20),
          ),
        ),
      ],
    );
  }
}
