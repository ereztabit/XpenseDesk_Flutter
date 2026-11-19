import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// Mobile: the "Awaiting approval" banner of a submitted budget, folded into
/// the back row's free end (FS-1025 #21) - the place an approved budget uses
/// for its downloads - so the page starts higher. Same amber as the desktop
/// [BudgetStatusStrip]; its "can still edit" line is the tooltip.
class BudgetAwaitingChip extends ConsumerWidget {
  const BudgetAwaitingChip({super.key, required this.sheet});

  final ExpenseSheetDetail sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sent = sheet.submittedAt;
    return Tooltip(
      message: l10n.budgetsCanStillEdit,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.amber.withAlpha(25),
          border: Border.all(color: AppTheme.amber.withAlpha(102)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, size: 16, color: AppTheme.amber),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.budgetsTileAwaiting,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.amber),
                ),
                if (sent != null)
                  Text(
                    sent.toCompanyDate(ref.watch(companyLocaleProvider)),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
