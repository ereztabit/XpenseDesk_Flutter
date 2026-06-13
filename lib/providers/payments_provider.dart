import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paged_payments.dart';
import '../models/payments_filter.dart';
import '../services/excel_export_service.dart';
import '../services/payment_service.dart';
import 'auth_provider.dart';

/// Singleton provider for the PaymentService.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// The APPLIED report filter (the screen edits a pending copy and commits it
/// here on Search). Deliberately non-autoDispose so the filter survives
/// navigating away and back within the session — the spec's filter-retention
/// requirement.
final paymentsFilterProvider =
    NotifierProvider<PaymentsFilterNotifier, PaymentsFilter>(
  PaymentsFilterNotifier.new,
);

class PaymentsFilterNotifier extends Notifier<PaymentsFilter> {
  @override
  PaymentsFilter build() => PaymentsFilter.defaults;

  void set(PaymentsFilter filter) => state = filter;

  void reset() => state = PaymentsFilter.defaults;
}

/// The current report page. Re-fetches whenever the APPLIED filter changes
/// (commit-on-Search) and exposes in-place mutations so a successful process
/// keeps the manager's scroll/filter context without a refetch.
final paymentsResultProvider =
    AsyncNotifierProvider<PaymentsResultNotifier, PagedPayments>(
  PaymentsResultNotifier.new,
);

class PaymentsResultNotifier extends AsyncNotifier<PagedPayments> {
  static const int pageSize = 100;

  @override
  Future<PagedPayments> build() async {
    if (ref.watch(userInfoProvider) == null) return PagedPayments.empty;
    final filter = ref.watch(paymentsFilterProvider);
    final service = ref.watch(paymentServiceProvider);
    return service.getPayments(filter, pageSize: pageSize);
  }

  /// Force a re-fetch of the current filter (e.g. after a concurrency
  /// conflict, or Search pressed again with unchanged values).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final filter = ref.read(paymentsFilterProvider);
      final service = ref.read(paymentServiceProvider);
      return service.getPayments(filter, pageSize: pageSize);
    });
  }

  /// Drops just-processed sheets from the page in place (Awaiting filter view)
  /// — preserves scroll position per the in-place-update requirement.
  void removeSheets(Set<String> sheetIds) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.withoutSheets(sheetIds));
  }
}

/// Which export is currently running (drives the button spinners).
class PaymentsExportState {
  final bool exportingAll;
  final bool exportingSelected;

  const PaymentsExportState({
    this.exportingAll = false,
    this.exportingSelected = false,
  });
}

final paymentsExportProvider =
    NotifierProvider<PaymentsExportNotifier, PaymentsExportState>(
  PaymentsExportNotifier.new,
);

/// Runs the two .xlsx exports and triggers the browser download.
/// "Export All" sends the APPLIED filter (the server exports the full
/// filtered set — never page-walk); "Export selected" sends sheet ids.
/// Returns false on failure so the screen can toast.
class PaymentsExportNotifier extends Notifier<PaymentsExportState> {
  @override
  PaymentsExportState build() => const PaymentsExportState();

  static String _datedFileName(String base) =>
      '$base-${DateTime.now().toIso8601String().split('T').first}.xlsx';

  Future<bool> exportAll() async {
    if (state.exportingAll) return true;
    state = const PaymentsExportState(exportingAll: true);
    try {
      final service = ref.read(paymentServiceProvider);
      final bytes =
          await service.exportPaymentsReport(ref.read(paymentsFilterProvider));
      ExcelExportService.downloadXlsxBytes(
          bytes, _datedFileName('payments-report'));
      return true;
    } catch (_) {
      return false;
    } finally {
      state = const PaymentsExportState();
    }
  }

  Future<bool> exportSelected(List<String> expenseSheetIds) async {
    if (state.exportingSelected || expenseSheetIds.isEmpty) return true;
    state = const PaymentsExportState(exportingSelected: true);
    try {
      final service = ref.read(paymentServiceProvider);
      final bytes = await service.exportSelectedPayments(expenseSheetIds);
      ExcelExportService.downloadXlsxBytes(
          bytes, _datedFileName('payments-selected'));
      return true;
    } catch (_) {
      return false;
    } finally {
      state = const PaymentsExportState();
    }
  }
}
