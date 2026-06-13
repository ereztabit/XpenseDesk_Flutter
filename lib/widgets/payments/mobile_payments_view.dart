import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import '../app_button.dart';
import '../manager_dashboard/paging_overflow_notice.dart';
import 'mobile_bulk_action_card.dart';
import 'mobile_payments_table.dart';
import 'payments_active_filter_badge.dart';

/// Mobile composition of the Payments Report body (D16/D17): pinned title row
/// (back · title · filter badge · Export All), animated bulk card, caption,
/// and the internally-scrolling mobile table. Filters live behind the
/// tune-icon dialog. Watches the shared payments providers itself; the screen
/// passes only screen-local state and handlers.
class MobilePaymentsView extends ConsumerWidget {
  const MobilePaymentsView({
    super.key,
    required this.onOpenFilters,
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
    required this.onMarkProcessedRow,
  });

  final VoidCallback onOpenFilters;
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
  final ValueChanged<PaymentReportRow> onMarkProcessedRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;
    final resultAsync = ref.watch(paymentsResultProvider);
    final exportState = ref.watch(paymentsExportProvider);
    final appliedFilter = ref.watch(paymentsFilterProvider);
    final paged = resultAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppTheme.foreground),
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Text(
                l10n.paymentsTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PaymentsActiveFilterBadge(
              activeCount: appliedFilter.activeCount,
              onTap: onOpenFilters,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: l10n.exportAll,
              variant: AppButtonVariant.normal,
              icon: Icons.download_outlined,
              dense: true,
              isLoading: exportState.exportingAll,
              onPressed: onExportAll,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: selectedIds.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: MobileBulkActionCard(
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
        const SizedBox(height: 12),
        Text(
          l10n.selectSheetsCaption,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: MobilePaymentsTable(
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
            onMarkProcessed: onMarkProcessedRow,
          ),
        ),
        if (paged != null && paged.hasMore)
          PagingOverflowNotice(
            shown: paged.items.length,
            total: paged.totalCount,
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
