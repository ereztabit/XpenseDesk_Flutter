import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../models/payment_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';
import '../../utils/payments_utils.dart';
import 'edit_payment_dialog.dart';
import 'mark_processed_dialog.dart';

/// The Payments Report's selection, payment and export actions (kept out of
/// the screen file).
mixin PaymentsReportActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Set<String> get selectedIds;

  /// Rows flagged by a concurrency conflict (processed elsewhere meanwhile).
  Set<String> get highlightedIds;

  void toggleSelection(PaymentReportRow row, bool selected) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (!selected) {
        selectedIds.remove(row.expenseSheetId);
      } else if (selectedIds.length >= PaymentService.maxBatchSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tooManySheetsSelected),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        selectedIds.add(row.expenseSheetId);
      }
    });
  }

  void toggleAll(List<PaymentReportRow> rows, bool selectAll) {
    setState(() {
      selectedIds.clear();
      if (selectAll) {
        selectedIds.addAll(
          rows
              .where((r) => r.isAwaiting)
              .take(PaymentService.maxBatchSize)
              .map((r) => r.expenseSheetId),
        );
      }
    });
  }

  /// Net amount of [ids] for the dialog summary ("-₪10.00") - one short
  /// figure on a phone (owner, 2026-11-18).
  String _amountTextFor(Set<String> ids) {
    final rows =
        ref.read(paymentsResultProvider).asData?.value.items ??
        const <PaymentReportRow>[];
    return paymentNetText(
      PaymentsSelectionUtils.totalsFor(rows, ids),
      ref.read(companyLocaleProvider),
      ref.read(userInfoProvider)?.currencyCode,
    );
  }

  Future<void> markProcessed(List<String> ids) async {
    final processed = await MarkProcessedDialog.show(
      context,
      expenseSheetIds: ids,
      amountText: _amountTextFor(ids.toSet()),
      onConflict: (offendingIds) {
        if (!mounted) return;
        setState(() {
          highlightedIds
            ..clear()
            ..addAll(offendingIds);
          selectedIds.clear();
        });
        ref.read(paymentsResultProvider.notifier).refresh();
      },
    );
    if (!processed || !mounted) return;

    setState(() {
      selectedIds.removeAll(ids);
      highlightedIds.clear();
    });
    // Re-opening a processed sheet must show the fresh payment strip.
    for (final id in ids) {
      ref.invalidate(sheetDetailProvider(id));
    }
    ref.invalidate(sheetTypePaymentsSummaryProvider);
    final applied = ref.read(paymentsFilterProvider);
    if (applied.status == PaymentStatus.awaitingPayment) {
      // In-place removal preserves scroll/filter context (spec §4).
      ref.read(paymentsResultProvider.notifier).removeSheets(ids.toSet());
    } else {
      // Under All/Processed views the rows change rather than leave — refetch.
      await ref.read(paymentsResultProvider.notifier).refresh();
    }
  }

  /// Per-row "Edit" — the unified payment-status dialog (mark processed / edit
  /// details / revert) for any row. On success refresh the list + the sheet's
  /// detail view (status may have changed in either direction).
  Future<void> editRow(PaymentReportRow row) async {
    final saved = await EditPaymentDialog.show(
      context,
      expenseSheetId: row.expenseSheetId,
      currentStatus: row.paymentStatus ?? PaymentStatus.awaitingPayment,
      amountText: _amountTextFor({row.expenseSheetId}),
      initialDate: row.processedDate,
      initialNote: row.note,
      onConflict: () {
        // Status changed elsewhere — refresh so the stale row updates.
        ref.invalidate(sheetDetailProvider(row.expenseSheetId));
        ref.read(paymentsResultProvider.notifier).refresh();
      },
    );
    if (!saved || !mounted) return;
    setState(() {
      selectedIds.remove(row.expenseSheetId);
      highlightedIds.clear();
    });
    ref
      ..invalidate(sheetDetailProvider(row.expenseSheetId))
      ..invalidate(sheetTypePaymentsSummaryProvider);
    await ref.read(paymentsResultProvider.notifier).refresh();
  }

  /// Runs an export; on success, optionally offers to mark the exported
  /// sheets as processed (QA items 2/3 — the Excel export may itself be the
  /// payment act, so prompt with the same confirm modal pre-targeting them).
  Future<void> _runExport(
    Future<bool> Function() export, {
    List<String> offerProcessIds = const [],
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await export();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericErrorRetry),
          backgroundColor: AppTheme.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (offerProcessIds.isNotEmpty) await markProcessed(offerProcessIds);
  }

  void exportAll() {
    // Offer to process only when the whole filtered set is on the page — if
    // there's an overflow (hasMore), the loaded awaiting rows are a subset and
    // silently processing just those would mislead. There the manager selects
    // explicitly instead (the 100-cap is visible in that flow).
    final paged = ref.read(paymentsResultProvider).asData?.value;
    final awaitingIds = (paged != null && !paged.hasMore)
        ? paged.items
              .where((r) => r.isAwaiting)
              .map((r) => r.expenseSheetId)
              .toList()
        : <String>[];
    _runExport(
      ref.read(paymentsExportProvider.notifier).exportAll,
      offerProcessIds: awaitingIds,
    );
  }

  void exportSelected() {
    final ids = selectedIds.toList();
    _runExport(
      () => ref.read(paymentsExportProvider.notifier).exportSelected(ids),
      offerProcessIds: ids,
    );
  }
}
