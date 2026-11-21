import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_usage.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_table_layout_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import 'ai_row_action.dart';
import '../admin_fixed_table.dart';

/// The Usage summary: one row per model chain (or profile) with review counts
/// and an accuracy bar. "View scans" lists that row's expenses below.
class AiUsageTable extends ConsumerWidget {
  const AiUsageTable({super.key});

  static const double _rowHeight = 58;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiUsageProvider);
    final byModel = ref.watch(adminAiGroupByProvider) == AdminAiGroupBy.model;
    final picked = ref.watch(adminAiPickedRowProvider);
    final rows = async.asData?.value.rows ?? const <AdminAiUsageRow>[];
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);
    const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    String title(AdminAiUsageRow r) => byModel
        ? adminAiModelLabel(l10n, r.key)
        : r.key == null
        ? l10n.adminAiModelUnknown
        : adminAiProfileLabel(r.aiProfileId, r.aiProfileName);

    Widget accuracy(AdminAiUsageRow r) {
      final pct = aiAccuracyPercent(r.verified, r.corrected);
      final color = adminAiAccuracyColor(aiAccuracyTier(pct));
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (pct ?? 0) / 100,
                minHeight: 8,
                backgroundColor: AppTheme.muted,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(pct == null ? '—' : '$pct%', style: cell.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }

    return SizedBox(
      height: 46 + _rowHeight * (rows.isEmpty ? 2 : rows.length),
      // Fits its card, View scans included, from a 768px screen up.
      child: LayoutBuilder(
        builder: (context, c) {
          final widths = aiFitColumns(c.maxWidth, aiUsageTableColumns, flex: 0, minFlex: 200);
          return AdminFixedTable(
            columns: aiFitTableColumns([
              byModel ? l10n.adminAiColModel : l10n.adminAiColProfile,
              l10n.adminAiColUploads,
              l10n.adminAiColVerified,
              l10n.adminAiColCorrected,
              l10n.adminAiColNotReviewed,
              l10n.adminAiColAccuracy,
              '',
            ], widths),
            loading: async.isLoading,
            error: async.hasError ? l10n.adminAiLoadError : null,
            emptyMessage: l10n.adminAiNoScans,
            rows: [
              for (final r in rows)
                aiFitCells([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title(r), style: cell.copyWith(fontWeight: FontWeight.w600)),
                      if (byModel && r.key != null)
                        Text(
                          r.key!,
                          overflow: TextOverflow.ellipsis,
                          style: muted.copyWith(fontFamily: 'monospace'),
                        ),
                    ],
                  ),
                  Text('${r.uploads}', style: cell.copyWith(fontWeight: FontWeight.w700)),
                  Text('${r.verified}', style: cell),
                  Text('${r.corrected}', style: cell),
                  Text('${r.notReviewed}', style: cell),
                  accuracy(r),
                  // The row action, as in the other admin tables; filled while shown.
                  AiRowAction(
                    icon: picked.picked && picked.key == r.key ? Icons.visibility : Icons.visibility_outlined,
                    tooltip: picked.picked && picked.key == r.key ? l10n.adminAiShowing : l10n.adminAiViewScans,
                    onPressed: () => ref.read(adminAiPickedRowProvider.notifier).set((picked: true, key: r.key)),
                  ),
                ], widths),
            ],
          );
        },
      ),
    );
  }
}
