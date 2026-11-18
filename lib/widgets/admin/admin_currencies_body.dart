import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_currency_status.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_currency_utils.dart';
import '../app_button.dart';
import 'admin_currency_runs_table.dart';
import 'admin_currencies_table.dart';

/// The Currencies module's body (FS-1019): the newest Bank of Israel date, the
/// Sync now button, the per-currency table and the recent syncs.
///
/// Must be given a bounded height - both tables scroll their own rows.
class AdminCurrenciesBody extends ConsumerStatefulWidget {
  const AdminCurrenciesBody({super.key});

  @override
  ConsumerState<AdminCurrenciesBody> createState() => _AdminCurrenciesBodyState();
}

class _AdminCurrenciesBodyState extends ConsumerState<AdminCurrenciesBody> {
  bool _syncing = false;
  AdminCurrencySyncRunSummary? _lastResult;

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);

    try {
      final run = await ref.read(adminServiceProvider).syncCurrenciesNow();
      if (!mounted) return;
      setState(() => _lastResult = run.summary);
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminCurrenciesSyncDone)));
    } on AdminException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.errorCode == 'CurrencySyncAlreadyRunning'
            ? l10n.adminCurrenciesSyncAlreadyRunning
            : l10n.adminCurrenciesSyncFailed),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminCurrenciesSyncFailed)));
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
        ref.invalidate(adminCurrencyOverviewProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(adminCurrencyOverviewProvider);
    final data = overview.asData?.value;
    final error = overview.hasError ? l10n.genericErrorRetry : null;
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              data == null
                  ? ''
                  : data.referenceRateDate == null
                      ? l10n.adminCurrenciesNoRates
                      : '${l10n.adminCurrenciesRatesUpTo} ${formatAdminDate(data.referenceRateDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppButton(
              label: _syncing ? l10n.adminCurrenciesSyncing : l10n.adminCurrenciesSyncNow,
              icon: Icons.sync,
              dense: true,
              isLoading: _syncing,
              onPressed: _syncing ? null : _syncNow,
            ),
          ],
        ),
        if (_lastResult?.emailSubject != null) ...[
          const SizedBox(height: 6),
          SelectableText(_lastResult!.emailSubject!, style: muted),
        ],
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: AdminCurrenciesTable(
            currencies: data?.currencies ?? const [],
            loading: overview.isLoading,
            error: error,
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.adminCurrenciesRecentRuns, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: AdminCurrencyRunsTable(
            runs: data?.recentRuns ?? const [],
            loading: overview.isLoading,
            error: error,
          ),
        ),
      ],
    );
  }
}
