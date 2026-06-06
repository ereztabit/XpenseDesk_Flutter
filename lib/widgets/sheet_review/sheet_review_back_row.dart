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
  const SheetReviewBackRow({
    super.key,
    required this.title,
    this.fallbackRoute = '/manager-approvals',
  });

  final String title;

  /// Where to go when there is nothing to pop — e.g. Sheet Review was opened via
  /// a deep link or after a browser refresh, so it is the only route on the
  /// stack and `maybePop()` would silently do nothing.
  final String fallbackRoute;

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

    if (context.isMobile) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
            tooltip: l10n.backToApprovals,
            onPressed: () => _back(context),
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
          label: l10n.backToApprovals,
          variant: AppButtonVariant.ghost,
          icon: Icons.arrow_back,
          onPressed: () => _back(context),
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
