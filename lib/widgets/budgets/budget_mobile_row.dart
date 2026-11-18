import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../employee_dashboard/sheet_status_badge.dart';
import '../manager_dashboard/usage_bar.dart';
import 'budget_reason_line.dart';

/// B2 mobile card row (< 768px): name + "#number" + balance; holder, usage bar
/// and %; the attention reason (if any); the status badge. Tap opens the
/// budget. The row ⋮ menu arrives with PC-2.
class BudgetMobileRow extends StatelessWidget {
  const BudgetMobileRow({
    super.key,
    required this.budget,
    required this.locale,
    required this.reason,
    required this.onTap,
  });

  final Budget budget;
  final String locale;

  /// Attention reason, empty when none.
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = budget;
    final percent = budgetUsedPercent(b);
    const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Name + #number take the free width, so the balance sits at
                // the row's end however short the name is.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          b.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('#${b.number}', textDirection: TextDirection.ltr, style: muted),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.balance.toWholeCurrency(locale, b.currencyCode),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: budgetIsOverBudget(b) ? AppTheme.destructive : AppTheme.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.screenWidth * 0.4,
                  ),
                  child: Text(b.holderDisplayName, overflow: TextOverflow.ellipsis, style: muted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: UsageBar(fraction: budgetUsedFraction(b), breach: true, height: 6),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  textDirection: TextDirection.ltr,
                  style: muted.copyWith(
                    color: percent > 100 ? AppTheme.destructive : AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              BudgetReasonLine(text: reason),
            ],
            const SizedBox(height: 8),
            SheetStatusBadge(statusId: b.statusId),
          ],
        ),
      ),
    );
  }
}
