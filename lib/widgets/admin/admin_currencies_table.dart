import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_currency_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_currency_utils.dart';
import '../ltr_text.dart';
import 'admin_fixed_table.dart';
import 'admin_status_pill.dart';

/// Per-currency rate status (FS-1019): code, name, status, newest rate date and
/// rate, last check, rates stored. Read-only.
class AdminCurrenciesTable extends StatelessWidget {
  const AdminCurrenciesTable({
    super.key,
    required this.currencies,
    this.loading = false,
    this.error,
  });

  final List<AdminCurrencyRow> currencies;
  final bool loading;
  final String? error;

  static const _cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdminFixedTable(
      loading: loading,
      error: error,
      emptyMessage: l10n.adminCurrenciesNoRates,
      columns: [
        (label: l10n.adminCurrencyColumnCode, width: 80),
        (label: l10n.adminCurrencyColumnName, width: 180),
        (label: l10n.adminCurrencyColumnStatus, width: 130),
        (label: l10n.adminCurrencyColumnLastRateDate, width: 130),
        (label: l10n.adminCurrencyColumnLastRate, width: 140),
        (label: l10n.adminCurrencyColumnLastChecked, width: 150),
        (label: l10n.adminCurrencyColumnRateCount, width: 110),
      ],
      rows: [
        for (final c in currencies)
          [
            Text(c.currencyCode,
                style: _cell.copyWith(fontWeight: FontWeight.w600)),
            Text('${c.currencySymbol}  ${c.currencyName}',
                overflow: TextOverflow.ellipsis, style: _cell),
            Tooltip(
              message: c.lastError ?? '',
              child: () {
                final (label, color) =
                    adminCurrencyStatusVisual(l10n, c.status, c.rawStatus);
                return AdminStatusPill(label: label, color: color);
              }(),
            ),
            LtrText(formatAdminDate(c.lastRateDate), style: _cell),
            LtrText(
              c.lastRate == null
                  ? '-'
                  : formatAdminRate(c.lastRate!, c.lastUnitMult, l10n.adminCurrencyPer),
              style: _cell,
            ),
            LtrText(formatAdminStamp(c.lastCheckedAt), style: _cell),
            Text('${c.rateCount}', style: _cell),
          ],
      ],
    );
  }
}
