import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/company_module.dart';
import '../../models/payment_report_row.dart';
import '../../models/payments_filter.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/payments_provider.dart';
import '../../utils/app_navigator.dart';
import '../../utils/payments_utils.dart';

/// Payments and History are one screen behind two menu entries that share
/// [paymentsFilterProvider] (owner QA 2026-11-19). This keeps each open
/// screen on its own filter, and gives Reset and row taps the entry's rules.
mixin PaymentsScreenEntry<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The filter this screen last applied.
  PaymentsFilter get appliedHere;

  /// Called when the screen took its filter back (see [keepOwnFilter]).
  void onOwnFilterRestored(PaymentsFilter filter);

  /// Call from build: back on top after the other entry changed the shared
  /// filter (Payments -> History -> Back), it applies its own again.
  void keepOwnFilter() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (ref.read(paymentsFilterProvider) == appliedHere) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(paymentsFilterProvider) == appliedHere) return;
      ref.read(paymentsFilterProvider.notifier).set(appliedHere);
      onOwnFilterRestored(appliedHere);
    });
  }

  bool get _isPaymentsEntry =>
      ModalRoute.of(context)?.settings.name == AppRoutes.managerPayments;

  /// What Reset returns to: Pending on Payments, All on History.
  PaymentsFilter get resetFilter =>
      _isPaymentsEntry ? PaymentsFilter.pending : PaymentsFilter.defaults;

  /// The opening sort, again after each search: Payments by employee A-Z,
  /// History newest approval first (owner 2026-11-19).
  ({PaymentsSortField field, bool ascending}) get defaultSort =>
      _isPaymentsEntry
      ? (field: PaymentsSortField.employee, ascending: true)
      : (field: PaymentsSortField.approvedDate, ascending: false);

  /// Budget page; sheet review with Budgets off; read-only for History (D40).
  void openSheet(PaymentReportRow row) => Navigator.pushNamed(
    context,
    ref.read(paymentsHistoryOnlyProvider)
        ? AppRoutes.historySheetPath(row.expenseSheetId)
        : row.sheetType == CompanyModuleKey.pettyCash &&
              ref.read(isPettyCashEnabledProvider)
        ? AppRoutes.budgetPath(row.expenseSheetId)
        : '/manager/sheet/${row.expenseSheetId}',
  );
}
