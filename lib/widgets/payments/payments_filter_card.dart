import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../models/payments_filter.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import '../date_range_filter.dart';
import 'payments_advanced_filters.dart';
import 'payments_dropdown.dart';

/// Desktop filter card of the Payments Report: Payment Status + Approval Date
/// up top, an expandable Advanced section (Employee / Cycle / Processed Date),
/// and a bottom action row (Reset · Export All · Search).
///
/// Edits a PENDING copy of the filter via [onPendingChanged]; nothing hits the
/// API until [onSearch] commits (explicit-search UX). [onExportAll] null
/// renders the button disabled (wired in the exports phase).
class PaymentsFilterCard extends StatefulWidget {
  const PaymentsFilterCard({
    super.key,
    required this.pending,
    required this.onPendingChanged,
    required this.onSearch,
    required this.onReset,
    required this.onExportAll,
    this.isExporting = false,
    this.isSearching = false,
  });

  final PaymentsFilter pending;
  final ValueChanged<PaymentsFilter> onPendingChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;
  final VoidCallback? onExportAll;
  final bool isExporting;

  /// True while a search is in flight — the Search button spins and is locked
  /// so a slow query can't be re-fired (#search-spinner-and-lock).
  final bool isSearching;

  @override
  State<PaymentsFilterCard> createState() => _PaymentsFilterCardState();
}

class _PaymentsFilterCardState extends State<PaymentsFilterCard> {
  bool _advancedOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = widget.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              PaymentsDropdown<PaymentStatus?>(
                sectionLabel: l10n.paymentStatusFilterLabel,
                selected: pending.status,
                entries: [
                  DropdownMenuEntry<PaymentStatus?>(
                      value: null, label: l10n.allOption),
                  DropdownMenuEntry<PaymentStatus?>(
                      value: PaymentStatus.awaitingPayment,
                      label: l10n.awaitingPaymentLabel),
                  DropdownMenuEntry<PaymentStatus?>(
                      value: PaymentStatus.processed,
                      label: l10n.paymentStatusProcessed),
                ],
                onSelected: (value) => widget
                    .onPendingChanged(pending.copyWith(status: value)),
              ),
              DateRangeFilter(
                sectionLabel: l10n.approvalDateFilterLabel,
                from: pending.approvedFrom,
                to: pending.approvedTo,
                onChanged: (from, to) => widget.onPendingChanged(
                    pending.copyWith(approvedFrom: from, approvedTo: to)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _advancedOpen ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppTheme.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.advancedFiltersLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: AlignmentDirectional.topStart,
            child: _advancedOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: PaymentsAdvancedFilters(
                      pending: pending,
                      onChanged: widget.onPendingChanged,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              AppButton(
                label: l10n.resetFilters,
                variant: AppButtonVariant.ghost,
                icon: Icons.refresh,
                dense: true,
                onPressed: widget.onReset,
              ),
              const Spacer(),
              AppButton(
                label: l10n.exportAll,
                variant: AppButtonVariant.normal,
                icon: Icons.download_outlined,
                isLoading: widget.isExporting,
                onPressed: widget.onExportAll,
              ),
              const SizedBox(width: 8),
              AppButton(
                label: l10n.search,
                variant: AppButtonVariant.primary,
                icon: Icons.search,
                isLoading: widget.isSearching,
                onPressed: widget.onSearch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
