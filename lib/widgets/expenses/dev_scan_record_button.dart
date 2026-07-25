import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../services/json_viewer_service.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Dev-only debug button: fetches the receipt's scan-processing record and opens
/// it as raw JSON in a new browser tab. Renders nothing outside the dev build.
///
/// Give it [expenseId] for a saved expense and/or [fileUrl] (the
/// `altered_image_url` from the scan response) for a receipt that has been
/// scanned but not saved yet. Both may be passed — which route to use is
/// [ExpenseService.fetchScanRecord]'s call, not this widget's.
///
/// See docs/in-progress/receipt-scan-record-dev-viewer.md.
class DevScanRecordButton extends ConsumerStatefulWidget {
  final String? expenseId;
  final String? fileUrl;

  const DevScanRecordButton({super.key, this.expenseId, this.fileUrl});

  @override
  ConsumerState<DevScanRecordButton> createState() =>
      _DevScanRecordButtonState();
}

class _DevScanRecordButtonState extends ConsumerState<DevScanRecordButton> {
  bool _isLoading = false;

  bool get _hasTarget =>
      (widget.expenseId?.isNotEmpty ?? false) ||
      (widget.fileUrl?.isNotEmpty ?? false);

  Future<void> _fetchAndOpen() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final record = await ref.read(expenseServiceProvider).fetchScanRecord(
            expenseId: widget.expenseId,
            fileUrl: widget.fileUrl,
          );

      if (!mounted) return;

      // 404 is an expected outcome, not an error — receipts scanned before the
      // pipeline recorded them, manually attached images, no receipt at all.
      if (record == null) {
        _showMessage(l10n.devNoScanRecord, AppTheme.foreground);
        return;
      }

      JsonViewerService.openInNewTab(record, 'scan-record.json');
    } catch (e) {
      if (!mounted) return;
      _showMessage('${l10n.devScanRecordFailed}: $e', AppTheme.destructive);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.isDev || !_hasTarget) return const SizedBox.shrink();

    // Owns its own top gap so call sites insert one widget and a production
    // build renders nothing at all — not even a stray spacer.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppButton(
        label: l10n.devViewScanRecord,
        variant: AppButtonVariant.primary,
        icon: Icons.bug_report_outlined,
        dense: true,
        isLoading: _isLoading,
        onPressed: _fetchAndOpen,
      ),
    );
  }
}
