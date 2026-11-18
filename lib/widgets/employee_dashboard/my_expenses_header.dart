import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/free_receipts_provider.dart';
import '../../utils/new_expense_launcher.dart';
import '../bulk_upload/bulk_upload_entry_area.dart';
import 'page_header_row.dart';

/// The My expenses title row plus, on desktop with bulk upload on, the drop
/// strip directly under it (FS-1007, UI/UX guide §2.1). The New-expense button
/// routes through [startNewExpense], which adds the mobile choice sheet.
///
/// S3: on trial the strip carries the free-receipts meter; once they are used
/// up, both ways in are disabled and the used-up callout replaces the strip,
/// or sits under the title row where there is none — UI/UX guide §9.4. The
/// area under the title row is [BulkUploadEntryArea], shared with the budget
/// page (FS-1012).
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
    final canAdd =
        newExpenseEnabled && !ref.watch(currentFreeReceiptsProvider).isUsedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderRow(
          newExpenseEnabled: canAdd,
          onNewExpense: () =>
              startNewExpense(context, ref, onSingleDone: onSingleDone),
        ),
        BulkUploadEntryArea(enabled: canAdd),
      ],
    );
  }
}
