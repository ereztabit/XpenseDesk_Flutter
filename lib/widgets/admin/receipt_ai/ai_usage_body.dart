import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_usage.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_utils.dart';
import 'ai_tab_strip.dart';
import 'ai_usage_filters.dart';
import 'ai_usage_scans.dart';
import 'ai_usage_table.dart';

/// Receipt AI > Usage tab (FS-1026): AI-read expenses per model (or profile),
/// how many were reviewed and how many were right, and the scans of one row.
class AiUsageBody extends ConsumerWidget {
  const AiUsageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groupBy = ref.watch(adminAiGroupByProvider);
    final usage = ref.watch(adminAiUsageProvider);
    final picked = ref.watch(adminAiPickedRowProvider);
    final byModel = groupBy == AdminAiGroupBy.model;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiUsageFilters(),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    byModel ? l10n.adminAiUploadsByModel : l10n.adminAiUploadsByProfile,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    adminAiCount(
                      usage.asData?.value.total ?? 0,
                      l10n.adminAiAiReadExpensesOne,
                      l10n.adminAiAiReadExpenses,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              AiTabStrip(
                labels: [l10n.adminAiByModel, l10n.adminAiByProfile],
                activeIndex: byModel ? 0 : 1,
                onTap: (i) {
                  ref.read(adminAiGroupByProvider.notifier).set(i == 0 ? AdminAiGroupBy.model : AdminAiGroupBy.profile);
                  ref.read(adminAiPickedRowProvider.notifier).set((picked: false, key: null));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const AiUsageTable(),
          const SizedBox(height: 8),
          Text(l10n.adminAiUsageFootnote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          if (byModel) ...[
            const SizedBox(height: 4),
            Text(l10n.adminAiGptOnlyNote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          ],
          if (picked.picked) ...[const SizedBox(height: 28), const AiUsageScans()],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
