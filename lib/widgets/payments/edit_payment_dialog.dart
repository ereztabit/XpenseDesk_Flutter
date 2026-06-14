import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../providers/company_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/expense_service.dart'
    show SubscriptionRequiredException;
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import 'dialog_date_field.dart';
import 'dialog_text_field.dart';
import 'payments_dialog_header.dart';
import 'payments_dialog_summary.dart';

/// Edit-processed-details modal (Phase 9 / QA item 1). The manager corrects a
/// processed sheet's date / reference / note. There is no revert action —
/// editing covers every correction (user ruling: "I can change whatever I
/// want"). Status stays Processed, so [DialogDateField] is required.
class EditPaymentDialog extends ConsumerStatefulWidget {
  const EditPaymentDialog({
    super.key,
    required this.expenseSheetId,
    required this.amountText,
    required this.initialDate,
    this.initialReference,
    this.initialNote,
    this.onConflict,
  });

  final String expenseSheetId;

  /// Sheet's payable amount, pre-formatted — shown as context under the title.
  final String amountText;
  final DateTime initialDate;
  final String? initialReference;
  final String? initialNote;

  /// Fired when the sheet is no longer Processed (concurrent revert). The
  /// caller refreshes the list so the stale row updates while the dialog
  /// shows the explanation.
  final VoidCallback? onConflict;

  /// Returns true when the edit was saved.
  static Future<bool> show(
    BuildContext context, {
    required String expenseSheetId,
    required String amountText,
    required DateTime initialDate,
    String? initialReference,
    String? initialNote,
    VoidCallback? onConflict,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditPaymentDialog(
        expenseSheetId: expenseSheetId,
        amountText: amountText,
        initialDate: initialDate,
        initialReference: initialReference,
        initialNote: initialNote,
        onConflict: onConflict,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late DateTime _processedDate = widget.initialDate;
  late final TextEditingController _referenceController =
      TextEditingController(text: widget.initialReference ?? '');
  late final TextEditingController _noteController =
      TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(paymentServiceProvider);
      final summary = await service.updatePayment(
        widget.expenseSheetId,
        status: PaymentStatus.processed,
        processedDate: _processedDate,
        reference: _referenceController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;

      // Freshness rule: the write response carries the new summary.
      if (summary != null) {
        ref.read(companyProvider.notifier).updatePaymentsSummary(summary);
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.editPaymentSaved),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } on PaymentSheetNotProcessedException {
      // Concurrent revert — let the caller refresh so the message is true.
      widget.onConflict?.call();
      _fail(l10n.sheetNoLongerProcessed);
    } on SubscriptionRequiredException {
      _fail(l10n.actionSubscriptionRequired);
    } on PaymentException catch (e) {
      _fail(e.errorCode == 'MandatoryFieldsMissing'
          ? l10n.processedDateRequired
          : e.message);
    } catch (_) {
      _fail(l10n.genericErrorRetry);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PaymentsDialogHeader(
                title: l10n.editPaymentTitle,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              PaymentsDialogSummary(sheetCount: 1, amountText: widget.amountText),
              const SizedBox(height: 12),
              DialogDateField(
                label: l10n.processedDateFilterLabel,
                value: _processedDate,
                enabled: !_saving,
                onChanged: (date) => setState(() => _processedDate = date),
              ),
              const SizedBox(height: 16),
              DialogTextField(
                label: l10n.referenceIdField,
                controller: _referenceController,
                hint: l10n.referenceIdPlaceholder,
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              DialogTextField(
                label: l10n.noteField,
                controller: _noteController,
                hint: l10n.notePlaceholder,
                maxLines: 3,
                enabled: !_saving,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.destructive),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: l10n.cancel,
                    variant: AppButtonVariant.ghost,
                    dense: true,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l10n.confirm,
                    variant: AppButtonVariant.primary,
                    isLoading: _saving,
                    onPressed: _save,
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
