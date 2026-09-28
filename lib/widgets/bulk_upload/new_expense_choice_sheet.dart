import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import 'new_expense_choice_card.dart';

/// What the mobile "New expense" sheet resolved to.
enum NewExpenseChoice { oneReceipt, severalReceipts }

/// Mobile "New expense" choice sheet (UI/UX guide §2.2): one receipt (today's
/// flow) or several (the bulk sheet). Pops with the choice, or null on Cancel.
class NewExpenseChoiceSheet extends StatelessWidget {
  const NewExpenseChoiceSheet({super.key});

  static Future<NewExpenseChoice?> show(BuildContext context) {
    return showModalBottomSheet<NewExpenseChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.card,
      builder: (_) => const NewExpenseChoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.newExpense,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          NewExpenseChoiceCard(
            icon: Icons.receipt_long_outlined,
            title: l10n.bulkUploadOneReceipt,
            description: l10n.bulkUploadOneReceiptDesc,
            onTap: () =>
                Navigator.of(context).pop(NewExpenseChoice.oneReceipt),
          ),
          const SizedBox(height: 12),
          NewExpenseChoiceCard(
            icon: Icons.upload_file,
            title: l10n.bulkUploadSeveralReceipts,
            description: l10n.bulkUploadSeveralReceiptsDesc,
            onTap: () =>
                Navigator.of(context).pop(NewExpenseChoice.severalReceipts),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
