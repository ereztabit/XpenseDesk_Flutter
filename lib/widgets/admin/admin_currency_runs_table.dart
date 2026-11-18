import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_currency_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_currency_utils.dart';
import '../../utils/app_navigator.dart';
import '../action_icon_button.dart';
import '../ltr_text.dart';
import 'admin_fixed_table.dart';
import 'admin_status_pill.dart';

/// Recent currency syncs, newest first (FS-1019). The leading button opens the
/// run's detail at its own URL (`/admin/currencies/runs/{id}`).
class AdminCurrencyRunsTable extends StatelessWidget {
  const AdminCurrencyRunsTable({
    super.key,
    required this.runs,
    this.loading = false,
    this.error,
  });

  final List<AdminCurrencySyncRunSummary> runs;
  final bool loading;
  final String? error;

  static const _cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdminFixedTable(
      loading: loading,
      error: error,
      emptyMessage: l10n.adminCurrenciesNoRuns,
      columns: [
        (label: '', width: 56),
        (label: l10n.adminCurrencyColumnStarted, width: 150),
        (label: l10n.adminCurrencyColumnStatus, width: 120),
        (label: l10n.adminCurrencyColumnTrigger, width: 180),
        (label: l10n.adminCurrencyColumnRowsAdded, width: 110),
        (label: l10n.adminCurrencyRunEmailSubject, width: 420),
      ],
      rows: [
        for (final run in runs)
          [
            ActionIconButton(
              icon: Icons.open_in_new,
              tooltip: l10n.adminCurrencyRunOpen,
              color: AppTheme.primary,
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.adminCurrencyRun(run.syncRunId)),
            ),
            LtrText(formatAdminStamp(run.startedAt), style: _cell),
            () {
              final (label, color) =
                  adminCurrencyRunStatusVisual(l10n, run.status, run.rawStatus);
              return AdminStatusPill(label: label, color: color);
            }(),
            Text(adminCurrencyRunTrigger(l10n, run),
                overflow: TextOverflow.ellipsis, style: _cell),
            Text('${run.rowsInserted}', style: _cell),
            LtrText(run.emailSubject ?? run.error ?? '-',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: _cell),
          ],
      ],
    );
  }
}
