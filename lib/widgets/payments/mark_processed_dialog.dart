import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
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

/// Mark-as-Processed confirmation modal (D6 — pixel-faithful to the approved
/// mock): Processed Date (required, defaults today), Reference ID (optional),
/// Note (optional). Cancel / X / Esc / scrim close WITHOUT clearing the
/// caller's selection. Pops `true` only on success.
///
/// All-or-nothing semantics: on a concurrency conflict
/// (PaymentSheetNotAwaiting) nothing was processed — the dialog stays open
/// with an inline error and [onConflict] lets the caller refetch + highlight
/// the offending rows.
class MarkProcessedDialog extends ConsumerStatefulWidget {
  const MarkProcessedDialog({
    super.key,
    required this.expenseSheetIds,
    this.onConflict,
  });

  final List<String> expenseSheetIds;
  final ValueChanged<List<String>>? onConflict;

  /// Returns true when the batch was processed.
  static Future<bool> show(
    BuildContext context, {
    required List<String> expenseSheetIds,
    ValueChanged<List<String>>? onConflict,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MarkProcessedDialog(
        expenseSheetIds: expenseSheetIds,
        onConflict: onConflict,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<MarkProcessedDialog> createState() =>
      _MarkProcessedDialogState();
}

class _MarkProcessedDialogState extends ConsumerState<MarkProcessedDialog> {
  DateTime _processedDate = DateTime.now();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _processing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(paymentServiceProvider);
      final result = await service.processPayments(
        expenseSheetIds: widget.expenseSheetIds,
        processedDate: _processedDate,
        reference: _referenceController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;

      // Freshness rule: the write response carries the new summary.
      if (result.summary != null) {
        ref
            .read(companyProvider.notifier)
            .updatePaymentsSummary(result.summary!);
      }

      final sheetsLabel = result.processedCount == 1
          ? l10n.awaitingPaymentSheetSingular
          : l10n.awaitingPaymentSheetPlural;
      final reference = _referenceController.text.trim();
      final toast =
          '${l10n.processedToastPrefix} ${result.processedCount} $sheetsLabel'
          '${reference.isNotEmpty ? ' · $reference' : ''}';
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(toast),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } on PaymentSheetNotAwaitingException catch (e) {
      widget.onConflict?.call(e.offendingIds);
      _fail(l10n.sheetsNoLongerAwaiting);
    } on PaymentBulkLimitExceededException {
      _fail(l10n.tooManySheetsSelected);
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
      _processing = false;
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
                title: l10n.markSheetsProcessedTitle,
                enabled: !_processing,
              ),
              const SizedBox(height: 12),
              DialogDateField(
                label: l10n.processedDateFilterLabel,
                value: _processedDate,
                enabled: !_processing,
                onChanged: (date) => setState(() => _processedDate = date),
              ),
              const SizedBox(height: 16),
              DialogTextField(
                label: l10n.referenceIdField,
                controller: _referenceController,
                hint: l10n.referenceIdPlaceholder,
                enabled: !_processing,
              ),
              const SizedBox(height: 16),
              DialogTextField(
                label: l10n.noteField,
                controller: _noteController,
                hint: l10n.notePlaceholder,
                maxLines: 3,
                enabled: !_processing,
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
                    onPressed: _processing
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l10n.confirm,
                    variant: AppButtonVariant.primary,
                    isLoading: _processing,
                    onPressed: _confirm,
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
