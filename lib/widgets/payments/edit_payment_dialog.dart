import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../providers/company_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/expense_service.dart'
    show SubscriptionRequiredException;
import '../../services/payment_service.dart';
import 'payment_dialog_shell.dart';
import 'payment_status_edit_fields.dart';

/// Unified single-sheet payment-status editor (bugs #2 / #3 / #13), opened from
/// the per-row "Edit" button for both awaiting and processed sheets: mark
/// processed, edit the processed details, or revert to awaiting. The transition
/// routing lives in [PaymentService.applyStatusChange]. On a concurrency
/// conflict the dialog stays open with an inline error and calls [onConflict].
class EditPaymentDialog extends ConsumerStatefulWidget {
  const EditPaymentDialog({
    super.key,
    required this.expenseSheetId,
    required this.currentStatus,
    required this.amountText,
    this.initialDate,
    this.initialNote,
    this.onConflict,
  });

  final String expenseSheetId;
  final PaymentStatus currentStatus;
  final String amountText;
  final DateTime? initialDate;
  final String? initialNote;
  final VoidCallback? onConflict;

  /// Returns true when a change was saved.
  static Future<bool> show(
    BuildContext context, {
    required String expenseSheetId,
    required PaymentStatus currentStatus,
    required String amountText,
    DateTime? initialDate,
    String? initialNote,
    VoidCallback? onConflict,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditPaymentDialog(
        expenseSheetId: expenseSheetId,
        currentStatus: currentStatus,
        amountText: amountText,
        initialDate: initialDate,
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
  // Awaiting sheets open pre-set to Processed (the common action is to mark
  // them processed); processed sheets open on their current status.
  late PaymentStatus _status =
      widget.currentStatus == PaymentStatus.awaitingPayment
          ? PaymentStatus.processed
          : widget.currentStatus;
  late DateTime _processedDate = widget.initialDate ?? DateTime.now();
  late final TextEditingController _noteController =
      TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Note edits must re-evaluate the dirty check so Save can enable.
    _noteController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onFieldChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  /// Save is enabled only when the status changed, or (staying Processed) the
  /// date/note changed — mirrors the "update only when dirty" pattern.
  bool get _isDirty {
    if (_status != widget.currentStatus) return true;
    if (_status == PaymentStatus.processed) {
      final noteChanged =
          _noteController.text.trim() != (widget.initialNote ?? '').trim();
      final dateChanged = widget.initialDate == null ||
          !_sameDay(_processedDate, widget.initialDate!);
      return noteChanged || dateChanged;
    }
    return false;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final summary =
          await ref.read(paymentServiceProvider).applyStatusChange(
                expenseSheetId: widget.expenseSheetId,
                from: widget.currentStatus,
                to: _status,
                processedDate: _processedDate,
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
            content: Text(l10n.paymentStatusUpdatedToast),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } on PaymentSheetNotAwaitingException {
      widget.onConflict?.call();
      _fail(l10n.sheetsNoLongerAwaiting);
    } on PaymentSheetNotProcessedException {
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

    return PaymentDialogShell(
      title: l10n.editSheetsPaymentStatusTitle,
      sheetCount: 1,
      amountText: widget.amountText,
      busy: _saving,
      errorMessage: _errorMessage,
      confirmEnabled: _isDirty,
      onConfirm: _save,
      fields: [
        PaymentStatusEditFields(
          status: _status,
          processedDate: _processedDate,
          noteController: _noteController,
          enabled: !_saving,
          onStatusChanged: (s) => setState(() => _status = s),
          onDateChanged: (d) => setState(() => _processedDate = d),
        ),
      ],
    );
  }
}
