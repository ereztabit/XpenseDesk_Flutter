import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// The amber "Needs action" card above the My expenses list (bulk upload S2,
/// design guide §8.2): a header with the count, the cycle-day explanation,
/// and the flagged lines in [child] — the same list the regular expenses use,
/// never a copy of it.
///
/// Same amber box as [BulkUploadAmberNotice]: light amber fill, stronger amber
/// border, normal text color.
class NeedsActionSection extends StatelessWidget {
  const NeedsActionSection({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amberBorder = AppTheme.amber.withAlpha(153);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: AppTheme.amber),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.actionRequiredTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: amberBorder),
                ),
                child: Text(
                  '$count',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.actionRequiredExplanation,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
