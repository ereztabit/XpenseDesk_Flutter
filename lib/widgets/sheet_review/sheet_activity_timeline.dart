import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_log_entry.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'sheet_activity_timeline_entry.dart';

/// The sheet's status-log audit trail, rendered as a vertical timeline.
/// Hidden entirely when the log is empty.
class SheetActivityTimeline extends ConsumerWidget {
  const SheetActivityTimeline({
    super.key,
    required this.log,
    this.isBudget = false,
    this.currencyCode,
  });

  final List<ExpenseSheetLogEntry> log;

  /// FS-1012 S3: a budget's trail reads "Budget created / Submitted for
  /// approval / Returned for changes / Approved".
  final bool isBudget;

  /// FS-1013 PC-2: the budget's currency, for the amount events; null = the
  /// company's base currency.
  final String? currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FS-1013: an event type this build does not know is skipped, never
    // shown as a status change (forward compatible with new server events).
    final shown = log
        .where((e) => e.isStatusChange || BudgetLogEvent.fromId(e.eventTypeId) != null)
        .toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activityTimelineTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(shown.length, (index) {
              return SheetActivityTimelineEntry(
                entry: shown[index],
                companyLocale: companyLocale,
                isLast: index == shown.length - 1,
                isBudget: isBudget,
                currencyCode: currencyCode ?? ref.watch(companyBaseCurrencyProvider),
              );
            }),
          ],
        ),
      ),
    );
  }
}
