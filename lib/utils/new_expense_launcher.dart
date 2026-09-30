import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bulk_upload_provider.dart';
import '../providers/free_receipts_provider.dart';
import '../widgets/bulk_upload/bulk_upload_dialog.dart';
import '../widgets/bulk_upload/new_expense_choice_sheet.dart';
import 'app_navigator.dart';
import 'responsive_utils.dart';

/// Every "New expense" button on My expenses goes through here (FS-1007).
///
/// Desktop, or bulk upload off: straight to the single-receipt flow, as
/// before. Mobile with bulk upload on: the choice sheet first (UI/UX guide
/// §2.2). [onSingleDone] runs when the single flow returns, so the caller can
/// refresh its list — a bulk batch files its expenses later, in the
/// background, so there is nothing to refresh after it.
Future<void> startNewExpense(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onSingleDone,
}) async {
  // S3 backstop: every entry point is disabled once the free receipts are
  // used up (UI/UX guide §9.4); a stale button must not open either flow.
  if (ref.read(currentFreeReceiptsProvider).isUsedUp) return;
  if (context.isMobile && ref.read(isBulkUploadEnabledProvider)) {
    final choice = await NewExpenseChoiceSheet.show(context);
    if (!context.mounted || choice == null) return;
    if (choice == NewExpenseChoice.severalReceipts) {
      await showBulkUploadDialog(context);
      return;
    }
  }
  await Navigator.of(context).pushNamed(AppRoutes.employeeNewExpense);
  onSingleDone();
}
