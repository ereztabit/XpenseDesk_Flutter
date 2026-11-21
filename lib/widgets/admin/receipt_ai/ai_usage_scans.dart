import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_usage.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_table_layout_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/app_navigator.dart';
import '../../app_button.dart';
import 'ai_tab_strip.dart';
import '../admin_fixed_table.dart';
import '../admin_status_pill.dart';
import 'ai_row_action.dart';

/// The API returns at most this many scans per list.
const int kAiScanListMax = 500;

/// The scans of the picked Usage row, filtered by review status. Opening one
/// hands the list to the review screen so it can walk it (Next unreviewed).

class AiUsageScans extends ConsumerWidget {
  const AiUsageScans({super.key});

  /// Review-status switch values, in tab order (null = all).
  static const List<int?> _statuses = [0, 2, 1, null];

  void _open(BuildContext context, WidgetRef ref, List<AdminAiScanRow> rows, String expenseId) {
    ref.read(adminAiScanQueueProvider.notifier).set([for (final r in rows) r.expenseId]);
    ref.read(adminAiReviewedIdsProvider.notifier).set({
      for (final r in rows)
        if (r.aiReviewStatusId != null) r.expenseId,
    });
    Navigator.of(context).pushNamed(AppRoutes.adminAiScan(expenseId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiScansProvider);
    final status = ref.watch(adminAiReviewStatusFilterProvider);
    final rows = async.asData?.value ?? const <AdminAiScanRow>[];
    final firstUnreviewed = firstUnreviewedAiScan(rows);
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title, then the status tabs and Review next on one line; below 600px
        // stacked, Review next full width (as the JSON card).
        LayoutBuilder(
          builder: (context, c) {
            final title = Text(
              '${l10n.adminAiScansTitle} · ${rows.length}${rows.length >= kAiScanListMax ? ' · ${l10n.adminAiFirst500}' : ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            );
            final tabs = AiTabStrip(
              labels: [
                l10n.adminAiReviewNot,
                l10n.adminAiReviewCorrected,
                l10n.adminAiReviewVerified,
                l10n.adminAiReviewAll,
              ],
              activeIndex: _statuses.indexOf(status),
              onTap: (i) => ref.read(adminAiReviewStatusFilterProvider.notifier).set(_statuses[i]),
            );
            final next = AppButton(
              label: l10n.adminAiReviewNext,
              onPressed: firstUnreviewed == null ? null : () => _open(context, ref, rows, firstUnreviewed.expenseId),
            );
            if (c.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 8), tabs, const SizedBox(height: 8), next],
              );
            }
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                title,
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [tabs, next]),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 460,
          child: LayoutBuilder(
            builder: (context, c) {
              final widths = aiFitColumns(c.maxWidth, aiScanListColumns, flex: 1, minFlex: 140);
              return AdminFixedTable(
                columns: aiFitTableColumns([
                  l10n.adminAiColExpenseDate,
                  l10n.adminAiColCompany,
                  l10n.adminAiColMerchant,
                  l10n.adminAiColAmount,
                  l10n.adminAiColProfile,
                  l10n.adminAiColModel,
                  l10n.adminAiColReview,
                  '',
                ], widths),
                loading: async.isLoading,
                error: async.hasError ? l10n.adminAiLoadError : null,
                emptyMessage: l10n.adminAiNoScans,
                rows: [
                  for (final r in rows)
                    () {
                      final (label, color) = adminAiReviewLabel(l10n, r.aiReviewStatusId);
                      return aiFitCells(<Widget>[
                        Text(adminAiDay(r.expenseDate), style: cell),
                        Text(r.companyName, overflow: TextOverflow.ellipsis, style: cell),
                        Text(
                          r.merchantName ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: cell.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(adminAiAmount(r.amount, r.baseCurrencyCode), style: cell),
                        Text(
                          adminAiProfileLabel(r.aiProfileId, r.aiProfileName),
                          overflow: TextOverflow.ellipsis,
                          style: cell,
                        ),
                        Text(adminAiModelLabel(l10n, r.aiModel), overflow: TextOverflow.ellipsis, style: cell),
                        AdminStatusPill(label: label, color: color),
                        AiRowAction(
                          icon: Icons.fact_check_outlined,
                          tooltip: l10n.adminAiOpen,
                          onPressed: () => _open(context, ref, rows, r.expenseId),
                        ),
                      ], widths);
                    }(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
