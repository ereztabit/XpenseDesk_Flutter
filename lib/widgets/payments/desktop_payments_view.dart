import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../models/payments_filter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/payments_utils.dart';
import '../manager_dashboard/paging_overflow_notice.dart';
import 'desktop_bulk_action_bar.dart';
import 'desktop_payments_table.dart';
import 'payments_filter_card.dart';
import 'payments_found_caption.dart';

/// Desktop composition of the Payments Report body. The whole view flows with
/// the page (no inner vertical scroll — #6); the table sizes to its rows and
/// only scrolls horizontally for the wide column set. Watches the shared
/// payments providers itself; the screen passes only screen-local state
/// (pending filter, sort, selection) and handlers.
class DesktopPaymentsView extends ConsumerWidget {
  const DesktopPaymentsView({
    super.key,
    required this.pending,
    required this.onPendingChanged,
    required this.onSearch,
    required this.onReset,
    required this.onExportAll,
    required this.onExportSelected,
    required this.onMarkProcessedSelection,
    required this.rows,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.selectedIds,
    required this.highlightedIds,
    required this.onToggleSelection,
    required this.onToggleAll,
    required this.onRowTap,
    required this.onEditRow,
    required this.horizontalScrollController,
  });

  final PaymentsFilter pending;
  final ValueChanged<PaymentsFilter> onPendingChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;
  final VoidCallback onExportAll;
  final VoidCallback onExportSelected;
  final VoidCallback onMarkProcessedSelection;
  final List<PaymentReportRow> rows;
  final PaymentsSortField? sortField;
  final bool sortAscending;
  final ValueChanged<PaymentsSortField> onSort;
  final Set<String> selectedIds;
  final Set<String> highlightedIds;
  final void Function(PaymentReportRow row, bool selected) onToggleSelection;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<PaymentReportRow> onRowTap;
  final ValueChanged<PaymentReportRow> onEditRow;
  final ScrollController horizontalScrollController;

  void _back(BuildContext context) {
    final nav = Navigator.of(context);
    nav.canPop() ? nav.pop() : nav.pushReplacementNamed(
        AppRoutes.managerDashboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;
    final resultAsync = ref.watch(paymentsResultProvider);
    final exportState = ref.watch(paymentsExportProvider);
    final paged = resultAsync.asData?.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppTheme.foreground),
              // canPop falls back to the dashboard so back works after a
              // browser refresh / deep link (nothing to pop otherwise).
              onPressed: () => _back(context),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.paymentsTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PaymentsFilterCard(
          pending: pending,
          onPendingChanged: onPendingChanged,
          onSearch: onSearch,
          onReset: onReset,
          onExportAll: onExportAll,
          isExporting: exportState.exportingAll,
          isSearching: resultAsync.isLoading,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: selectedIds.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DesktopBulkActionBar(
                    selectedCount: selectedIds.length,
                    amountText: PaymentsSelectionUtils.totalAmountTextFor(
                      rows,
                      selectedIds,
                      locale: locale,
                      currencyCode: currencyCode,
                    ),
                    onExport: onExportSelected,
                    onMarkProcessed: onMarkProcessedSelection,
                    isExporting: exportState.exportingSelected,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        PaymentsFoundCaption(
          rows: rows,
          locale: locale,
          currencyCode: currencyCode,
        ),
        const SizedBox(height: 8),
        DesktopPaymentsTable(
          rows: rows,
          locale: locale,
          currencyCode: currencyCode,
          loading: resultAsync.isLoading,
          error: resultAsync.hasError ? l10n.genericErrorRetry : null,
          sortField: sortField,
          sortAscending: sortAscending,
          onSort: onSort,
          selectedIds: selectedIds,
          highlightedIds: highlightedIds,
          onToggleSelection: onToggleSelection,
          onToggleAll: onToggleAll,
          onRowTap: onRowTap,
          onEdit: onEditRow,
          horizontalScrollController: horizontalScrollController,
        ),
        if (paged != null && paged.hasMore)
          PagingOverflowNotice(
            shown: paged.items.length,
            total: paged.totalCount,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
