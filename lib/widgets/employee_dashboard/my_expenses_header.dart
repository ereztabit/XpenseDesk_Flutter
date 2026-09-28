import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bulk_upload_provider.dart';
import '../../utils/new_expense_launcher.dart';
import '../../utils/responsive_utils.dart';
import '../bulk_upload/bulk_upload_dialog.dart';
import '../bulk_upload/bulk_upload_drop_strip.dart';
import '../bulk_upload/bulk_upload_progress_strip.dart';
import 'page_header_row.dart';

/// The My expenses title row plus, on desktop with bulk upload on, the drop
/// strip directly under it (FS-1007, UI/UX guide §2.1). The New-expense button
/// routes through [startNewExpense], which adds the mobile choice sheet.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderRow(
          newExpenseEnabled: newExpenseEnabled,
          onNewExpense: () =>
              startNewExpense(context, ref, onSingleDone: onSingleDone),
        ),
        if (bulkEnabled && context.isDesktop) ...[
          const SizedBox(height: 16),
          BulkUploadDropStrip(
            enabled: newExpenseEnabled,
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
