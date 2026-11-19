import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bulk_upload_provider.dart';
import '../../providers/free_receipts_provider.dart';
import '../../utils/responsive_utils.dart';
import '../free_receipts/free_receipts_callout.dart';
import '../free_receipts/free_receipts_meter.dart';
import 'bulk_upload_dialog.dart';
import 'bulk_upload_drop_strip.dart';
import 'bulk_upload_progress_strip.dart';

/// What sits under a page's "+ New Expense" (FS-1007, UI/UX guide §2.1,
/// §9.4): on desktop with bulk upload on, the drop strip (with the
/// free-receipts meter on trial); once the free receipts are used up, the
/// used-up callout instead - under the title row wherever there is no strip
/// (mobile, bulk upload off), since the limit is not tied to bulk upload; then
/// the progress strip of a batch being read.
///
/// Lifted out of My expenses' header so the budget page (FS-1012 S2b) shows
/// the same thing; [budgetId] sends a dropped batch into that budget.
class BulkUploadEntryArea extends ConsumerWidget {
  const BulkUploadEntryArea({super.key, required this.enabled, this.budgetId});

  /// The page allows a new expense (the free receipts are checked here).
  final bool enabled;
  final String? budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulkEnabled = ref.watch(isBulkUploadEnabledProvider);
    final freeReceipts = ref.watch(currentFreeReceiptsProvider);
    final usedUp = freeReceipts.isUsedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (usedUp) ...[
          const SizedBox(height: 16),
          const FreeReceiptsCallout(),
        ] else if (bulkEnabled && context.isDesktop) ...[
          const SizedBox(height: 16),
          BulkUploadDropStrip(
            enabled: enabled,
            trailing: freeReceipts.isLimited
                ? const FreeReceiptsMeter(width: 160)
                : null,
            onOpen: (files) => showBulkUploadDialog(context,
                initialFiles: files, budgetId: budgetId),
          ),
        ],
        // Under the strip on desktop, under the title row on mobile. Renders
        // nothing unless a batch is processing.
        BulkUploadProgressStrip(budgetId: budgetId),
      ],
    );
  }
}
