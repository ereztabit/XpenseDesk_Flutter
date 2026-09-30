import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bulk_upload_provider.dart';
import '../../providers/free_receipts_provider.dart';
import '../../utils/new_expense_launcher.dart';
import '../../utils/responsive_utils.dart';
import '../bulk_upload/bulk_upload_dialog.dart';
import '../bulk_upload/bulk_upload_drop_strip.dart';
import '../bulk_upload/bulk_upload_progress_strip.dart';
import '../free_receipts/free_receipts_callout.dart';
import '../free_receipts/free_receipts_meter.dart';
import 'page_header_row.dart';

/// The My expenses title row plus, on desktop with bulk upload on, the drop
/// strip directly under it (FS-1007, UI/UX guide §2.1). The New-expense button
/// routes through [startNewExpense], which adds the mobile choice sheet.
///
/// S3: on trial the strip carries the free-receipts meter; once they are used
/// up, both ways in are disabled and the used-up callout replaces the strip,
/// or sits under the title row where there is none — UI/UX guide §9.4.
class MyExpensesHeader extends ConsumerWidget {
  const MyExpensesHeader({
    super.key,
    required this.newExpenseEnabled,
    required this.onSingleDone,
  });

  /// Same rule for both paths: the current sheet is an editable draft.
  final bool newExpenseEnabled;
  final VoidCallback onSingleDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulkEnabled = ref.watch(isBulkUploadEnabledProvider);
    final freeReceipts = ref.watch(currentFreeReceiptsProvider);
    final usedUp = freeReceipts.isUsedUp;
    final canAdd = newExpenseEnabled && !usedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderRow(
          newExpenseEnabled: canAdd,
          onNewExpense: () =>
              startNewExpense(context, ref, onSingleDone: onSingleDone),
        ),
        // Used up: the callout replaces the drop strip, and stands under the
        // title row wherever there is no strip (mobile, bulk upload off) - the
        // limit is not tied to bulk upload.
        if (usedUp) ...[
          const SizedBox(height: 16),
          const FreeReceiptsCallout(),
        ] else if (bulkEnabled && context.isDesktop) ...[
          const SizedBox(height: 16),
          BulkUploadDropStrip(
            enabled: canAdd,
            trailing: freeReceipts.isLimited
                ? const FreeReceiptsMeter(width: 160)
                : null,
            onOpen: (files) =>
                showBulkUploadDialog(context, initialFiles: files),
          ),
        ],
        // Under the strip on desktop, under the title row on mobile. Renders
        // nothing unless a batch is processing.
        const BulkUploadProgressStrip(),
      ],
    );
  }
}
