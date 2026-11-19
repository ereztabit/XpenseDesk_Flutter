import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../sheet_review/payment_status_strip.dart';

/// Left-to-right isolate around a date inside an RTL text run.
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);

/// B4 status strip (FS-1012 S3, UX hand-off section 2.4): under the header
/// card while a budget is Awaiting approval ("Awaiting approval · sent {date}" /
/// "You can still edit expenses", amber) or Returned ("Returned for changes ·
/// {date}" / the manager's reason, red); once approved, the settlement
/// ([PaymentStatusStrip]). Nothing otherwise.
///
/// The `DeclinedSheetBanner` box (tinted fill, tinted border, icon + title +
/// body) - not that widget itself: its title names the manager and its body is
/// Monthly's auto-resubmit explainer, neither of which fits a budget.
class BudgetStatusStrip extends ConsumerWidget {
  const BudgetStatusStrip({super.key, required this.sheet});

  final ExpenseSheetDetail sheet;

  /// Whether the strip draws anything (Awaiting, Returned, settlement) - the page adds
  /// its spacing only then, so a Draft budget has no empty band.
  static bool shows(ExpenseSheetDetail sheet) =>
      sheet.paymentStatus != null ||
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id ||
      sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final status = ExpenseSheetStatus.fromId(sheet.expenseSheetStatusId);

    final String title;
    final String? body;
    final Color color;
    final IconData icon;
    if (status == ExpenseSheetStatus.waitingForApproval) {
      final sent = sheet.submittedAt;
      title = sent == null
          ? l10n.budgetsTileAwaiting
          : '${l10n.budgetsTileAwaiting} · ${_dated(l10n.budgetsSentPrefix, sent.toCompanyDate(locale))}';
      body = l10n.budgetsCanStillEdit;
      color = AppTheme.amber;
      icon = Icons.hourglass_top;
    } else if (status == ExpenseSheetStatus.declined) {
      final at = sheet.reviewedAt;
      title = at == null
          ? l10n.budgetsReturnedForChanges
          : '${l10n.budgetsReturnedForChanges} · $_lri${at.toCompanyDate(locale)}$_pdi';
      final reason = sheet.latestDeclineComment?.trim();
      body = reason == null || reason.isEmpty ? null : reason;
      color = AppTheme.destructive;
      icon = Icons.assignment_return;
    } else if (sheet.paymentStatus != null) {
      // Approved: what is paid to / collected from the holder, and when (PC-8).
      return PaymentStatusStrip(sheet: sheet);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // lines up with the cards
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        border: Border.all(color: color.withAlpha(102)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(fontSize: 13, color: AppTheme.foreground, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "sent 17/11/2026" / "נשלח ב-17.11.2026": a prefix ending in "-" joins
  /// the date with no space.
  String _dated(String prefix, String date) =>
      prefix.endsWith('-') ? '$prefix$_lri$date$_pdi' : '$prefix $_lri$date$_pdi';
}
