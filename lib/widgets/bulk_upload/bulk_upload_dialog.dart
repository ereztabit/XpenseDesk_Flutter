import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_state.dart';
import '../../providers/bulk_upload_dialog_provider.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';
import '../../utils/bulk_upload_validation_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/web_file_picker.dart';
import '../app_button.dart';
import 'bulk_upload_body.dart';
import 'bulk_upload_footer.dart';
import 'bulk_upload_header.dart';
import 'bulk_upload_shell.dart';
import 'bulk_upload_thanks.dart';
import 'confirm_choice_dialog.dart';

/// Opens the bulk upload container — a centred dialog on desktop, a
/// full-height bottom sheet on mobile (UI/UX guide §1.1, §3.1).
/// [initialFiles] come from a drop on the page strip (§2.1).
Future<void> showBulkUploadDialog(
  BuildContext context, {
  List<web.File> initialFiles = const [],
}) {
  final dialog = BulkUploadDialog(initialFiles: initialFiles);
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: AppTheme.card,
      builder: (_) => dialog,
    );
  }
  return showDialog<void>(context: context, builder: (_) => dialog);
}

/// Orchestrates one bulk upload: owns the leave guard, the tab-close warning,
/// the thanks auto-close and the flag-off close. State lives in
/// [bulkUploadDialogProvider]; every section is its own widget.
class BulkUploadDialog extends ConsumerStatefulWidget {
  const BulkUploadDialog({super.key, this.initialFiles = const []});

  final List<web.File> initialFiles;

  @override
  ConsumerState<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends ConsumerState<BulkUploadDialog> {
  Timer? _autoClose;
  bool _closing = false;

  /// Browser-level "leave site?" prompt while files are waiting/uploading
  /// (§3.7). The message itself is the browser's; it only needs cancelling.
  late final JSFunction _beforeUnload = ((web.BeforeUnloadEvent e) {
    if (!_counts.hasPending) return;
    e.preventDefault();
    e.returnValue = ''; // older Chromium/Safari only prompt when this is set
  }).toJS;

  BulkUploadCounts get _counts =>
      BulkUploadCounts.of(ref.read(bulkUploadDialogProvider).files);

  BulkUploadNotifier get _notifier =>
      ref.read(bulkUploadDialogProvider.notifier);

  @override
  void initState() {
    super.initState();
    web.window.addEventListener('beforeunload', _beforeUnload);
    if (widget.initialFiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.addFiles(widget.initialFiles);
      });
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    web.window.removeEventListener('beforeunload', _beforeUnload);
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  Future<void> _requestClose() async {
    if (_counts.hasPending) {
      final l10n = AppLocalizations.of(context)!;
      final leave = await ConfirmChoiceDialog.show(
        context,
        title: l10n.bulkUploadLeaveTitle,
        cancelLabel: l10n.bulkUploadStay,
        confirmLabel: l10n.bulkUploadLeave,
        confirmVariant: AppButtonVariant.destructive,
      );
      if (!leave) return;
    }
    _close();
  }

  Future<void> _confirmClearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final clear = await ConfirmChoiceDialog.show(
      context,
      title: l10n.bulkUploadClearConfirm,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.bulkUploadClearAction,
      confirmVariant: AppButtonVariant.destructive,
    );
    if (clear) _notifier.clearAll();
  }

  Future<void> _pick() async {
    final files = await pickWebFiles(kBulkUploadExtensions);
    if (mounted && files.isNotEmpty) _notifier.addFiles(files);
  }

  void _onStateChange(BulkUploadState? prev, BulkUploadState next) {
    if (next.isSent && prev?.isSent != true) {
      _autoClose = Timer(const Duration(seconds: 2), _close);
    }
    if (next.isDisabled && prev?.isDisabled != true) {
      // Flag switched off meanwhile (403): refresh so the entry points hide.
      ref.read(companyProvider.notifier).refresh();
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bulkUploadDialogProvider, _onStateChange);
    final state = ref.watch(bulkUploadDialogProvider);
    final counts = BulkUploadCounts.of(state.files);
    final isMobile = context.isMobile;

    final content = state.isSent
        ? BulkUploadThanks(onClose: _close)
        : Column(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BulkUploadHeader(
                  validCount: counts.valid, onClose: _requestClose),
              const SizedBox(height: 16),
              Flexible(
                fit: isMobile ? FlexFit.tight : FlexFit.loose,
                child: SingleChildScrollView(
                  child: BulkUploadBody(
                    state: state,
                    counts: counts,
                    onPick: _pick,
                    onDrop: _notifier.addFiles,
                    onClearAll: _confirmClearAll,
                    onRemove: _notifier.remove,
                    onRetry: _notifier.retry,
                    onUnsupportedExpired: _notifier.dismissUnsupportedNotice,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BulkUploadFooter(
                help: footerHelpFor(counts),
                sendCount: counts.valid,
                canSend: counts.canSend,
                isSending: state.isSending,
                onCancel: _requestClose,
                onSend: _notifier.send,
              ),
            ],
          );

    return PopScope(
      canPop: !counts.hasPending || _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: BulkUploadShell(isMobile: isMobile, child: content),
    );
  }
}
