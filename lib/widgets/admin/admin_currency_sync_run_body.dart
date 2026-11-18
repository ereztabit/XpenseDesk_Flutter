import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_currency_utils.dart';
import '../ltr_text.dart';
import 'admin_fixed_table.dart';
import 'admin_status_pill.dart';

/// One currency sync (FS-1019): when, who, outcome and subject, then one line per
/// currency with its window, rows, tries and error. Needs a bounded height.
class AdminCurrencySyncRunBody extends ConsumerWidget {
  const AdminCurrencySyncRunBody({super.key, required this.syncRunId});

  final int syncRunId;

  static const _cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminCurrencySyncRunProvider(syncRunId));
    final run = async.asData?.value;
    final notFound = async.error is AdminException &&
        (async.error as AdminException).errorCode == 'CurrencySyncRunNotFound';

    if (notFound) {
      return Center(
        child: Text(l10n.adminCurrencyRunNotFound,
            style: const TextStyle(color: AppTheme.mutedForeground)),
      );
    }

    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (run != null) ...[
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              () {
                final (label, color) = adminCurrencyRunStatusVisual(
                    l10n, run.summary.status, run.summary.rawStatus);
                return AdminStatusPill(label: label, color: color);
              }(),
              LtrText('#${run.summary.syncRunId}  ${formatAdminStamp(run.summary.startedAt)}',
                  style: muted),
              Text(adminCurrencyRunTrigger(l10n, run.summary), style: muted),
              Text('${run.summary.rowsInserted} ${l10n.adminCurrencyRunRowsAdded}', style: muted),
            ],
          ),
          const SizedBox(height: 6),
          if (run.summary.emailSubject != null)
            SelectableText(run.summary.emailSubject!,
                style: Theme.of(context).textTheme.titleSmall),
          if (run.summary.error != null) ...[
            const SizedBox(height: 4),
            SelectableText('${l10n.adminCurrencyRunError}: ${run.summary.error}',
                style: const TextStyle(color: AppTheme.destructive)),
          ],
          const SizedBox(height: 12),
        ],
        Expanded(
          child: AdminFixedTable(
            loading: async.isLoading,
            error: async.hasError ? l10n.genericErrorRetry : null,
            emptyMessage: l10n.adminCurrenciesNoRates,
            columns: [
              (label: l10n.adminCurrencyColumnCode, width: 80),
              (label: l10n.adminCurrencyColumnStatus, width: 130),
              (label: l10n.adminCurrencyColumnWindow, width: 210),
              (label: l10n.adminCurrencyColumnLastRateDate, width: 130),
              (label: l10n.adminCurrencyColumnLastRate, width: 140),
              (label: l10n.adminCurrencyColumnRows, width: 70),
              (label: l10n.adminCurrencyColumnRejected, width: 80),
              (label: l10n.adminCurrencyColumnAttempts, width: 70),
              (label: l10n.adminCurrencyColumnError, width: 320),
            ],
            rows: [
              for (final item in run?.items ?? const [])
                [
                  Text(item.currencyCode,
                      style: _cell.copyWith(fontWeight: FontWeight.w600)),
                  () {
                    final (label, color) =
                        adminCurrencyStatusVisual(l10n, item.status, item.rawStatus);
                    return AdminStatusPill(label: label, color: color);
                  }(),
                  LtrText('${formatAdminDate(item.fromDate)} - ${formatAdminDate(item.toDate)}',
                      style: _cell),
                  LtrText(formatAdminDate(item.newestRateDate), style: _cell),
                  LtrText(
                    item.newestRate == null
                        ? '-'
                        : formatAdminRate(item.newestRate!, item.unitMult, l10n.adminCurrencyPer),
                    style: _cell,
                  ),
                  Text('${item.rowsFetched}', style: _cell),
                  Text('${item.rowsRejected}', style: _cell),
                  Text('${item.attempts}', style: _cell),
                  Text(item.error ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _cell.copyWith(color: AppTheme.destructive)),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
