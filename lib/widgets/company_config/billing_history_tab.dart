import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/billing_transaction.dart';
import '../../providers/billing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../section_table.dart';

/// Billing History tab content — transactions table (Story 9).
class BillingHistoryTab extends ConsumerWidget {
  const BillingHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(billingTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Refresh button
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => ref.invalidate(billingTransactionsProvider),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.billingRefresh),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),

        transactionsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorCard(
            message: l10n.billingHistoryFailedToLoad,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(billingTransactionsProvider),
          ),
          data: (transactions) => _TransactionsTable(
            transactions: transactions,
            l10n: l10n,
            locale: ref.watch(companyLocaleProvider),
          ),
        ),
      ],
    );
  }
}

// ─── Transactions table using SectionTable ──────────────────────────────────

class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({
    required this.transactions,
    required this.l10n,
    required this.locale,
  });

  final List<BillingTransaction> transactions;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return SectionTable(
      title: l10n.billingHistoryTitle,
      count: transactions.length,
      summaryText: '',
      summaryColor: AppTheme.mutedForeground,
      initiallyExpanded: true,
      columns: [
        SectionTableColumn(label: l10n.billingHistoryDate, flex: 2),
        SectionTableColumn(label: l10n.billingHistoryAmount, flex: 2),
        SectionTableColumn(label: l10n.billingHistoryStatus, flex: 2),
        SectionTableColumn(label: l10n.billingHistoryInfo, flex: 4),
        SectionTableColumn(label: l10n.billingHistoryInvoice, flex: 2),
      ],
      rows: transactions.map((tx) => _buildRow(tx)).toList(),
      emptyState: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(
            l10n.billingHistoryEmpty,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRow(BillingTransaction tx) {
    return [
      // Date
      Text(
        tx.date.toMediumDate(locale),
        style: const TextStyle(fontSize: 14),
      ),

      // Amount
      Text(
        tx.amount.toSmartCurrency(locale, 'USD'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Status badge
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _StatusBadge(transaction: tx, l10n: l10n),
      ),

      // Info
      Text(
        tx.description,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.mutedForeground,
        ),
      ),

      // Invoice
      tx.hasInvoice
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openInvoice(tx.invoiceUrl!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.billingHistoryDownload,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Text(
              '-',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
    ];
  }

  void _openInvoice(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.transaction, required this.l10n});

  final BillingTransaction transaction;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final String label;

    if (transaction.isPaid) {
      textColor = AppTheme.success;
      bgColor = AppTheme.success.withAlpha(25);
      borderColor = AppTheme.success.withAlpha(77);
      label = l10n.billingHistoryStatusPaid;
    } else if (transaction.isFailed) {
      textColor = AppTheme.destructive;
      bgColor = AppTheme.destructive.withAlpha(25);
      borderColor = AppTheme.destructive.withAlpha(77);
      label = l10n.billingHistoryStatusFailed;
    } else {
      // Free — blue
      const blue = Color(0xFF3B82F6);
      textColor = blue;
      bgColor = blue.withAlpha(25);
      borderColor = blue.withAlpha(77);
      label = l10n.billingHistoryStatusFree;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Error card ─────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppTheme.destructive, size: 32),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
