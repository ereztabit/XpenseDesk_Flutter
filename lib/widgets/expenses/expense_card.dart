import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// A single row card showing a summary of one expense.
/// Tapping navigates to the expense detail screen (via [onTap]).
class ExpenseCard extends ConsumerWidget {
  final ExpenseSummary expense;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  Color _statusColor() {
    return switch (expense.expenseStatusId) {
      2 => AppTheme.success,
      3 => AppTheme.destructive,
      _ => AppTheme.amber, // 1 = Pending (default)
    };
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (expense.expenseStatusId) {
      2 => l10n.approved,
      3 => l10n.declined,
      _ => l10n.pending,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor();
    final locale = ref.watch(companyLocaleProvider);
    final dateFormatted = expense.expenseDate.toCompanyDate(locale);

    final title =
        expense.merchantName?.isNotEmpty == true
            ? expense.merchantName!
            : expense.categoryName;

    final amountText = expense.amount != null && expense.currencyCode != null
        ? expense.amount!.toCurrency(locale, expense.currencyCode!)
        : expense.amount != null
            ? expense.amount!.toFormattedNumber(locale)
            : '—';

    return Card(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Left: Title + category + date ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.categoryName} · $dateFormatted',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Right: Amount + status badge ───────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      amountText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(l10n),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
