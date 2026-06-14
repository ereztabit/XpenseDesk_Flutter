import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/company_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/expense_service.dart'
    show SubscriptionRequiredException;
import '../../services/payment_service.dart';
import 'dialog_date_field.dart';
import 'dialog_text_field.dart';
import 'payment_dialog_shell.dart';

/// Mark-as-Processed confirmation modal: Processed Date (required, defaults
/// today) and an optional Note. Cancel / X / Esc / scrim close WITHOUT clearing
/// the caller's selection. Pops `true` only on success.
///
/// All-or-nothing semantics: on a concurrency conflict
/// (PaymentSheetNotAwaiting) nothing was processed — the dialog stays open
/// with an inline error and [onConflict] lets the caller refetch + highlight
/// the offending rows.
class MarkProcessedDialog extends ConsumerStatefulWidget {
  const MarkProcessedDialog({
    super.key,
    required this.expenseSheetIds,
    required this.amountText,
    this.onConflict,
  });

  final List<String> expenseSheetIds;

  /// Combined payable total of the batch, pre-formatted in the company
  /// locale/currency — shown as context under the title.
  final String amountText;
  final ValueChanged<List<String>>? onConflict;

  /// Returns true when the batch was processed.
  static Future<bool> show(
    BuildContext context, {
    required List<String> expenseSheetIds,
    required String amountText,
    ValueChanged<List<String>>? onConflict,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MarkProcessedDialog(
        expenseSheetIds: expenseSheetIds,
        amountText: amountText,
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
  final _noteController = TextEditingController();
  bool _processing = false;
  String? _errorMessage;

  @override
  void dispose() {
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
      final toast =
          '${l10n.processedToastPrefix} ${result.processedCount} $sheetsLabel';
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

    return PaymentDialogShell(
      title: l10n.markSheetsProcessedTitle,
      sheetCount: widget.expenseSheetIds.length,
      amountText: widget.amountText,
      busy: _processing,
      errorMessage: _errorMessage,
      onConfirm: _confirm,
      fields: [
        DialogDateField(
          label: l10n.processedDateFilterLabel,
          value: _processedDate,
          enabled: !_processing,
          onChanged: (date) => setState(() => _processedDate = date),
        ),
        DialogTextField(
          label: l10n.noteField,
          controller: _noteController,
          maxLines: 3,
          enabled: !_processing,
        ),
      ],
    );
  }
}
