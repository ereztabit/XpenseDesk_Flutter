import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../models/bulk_upload_state.dart';
import '../../utils/bulk_upload_utils.dart';
import '../../utils/free_receipts_utils.dart';
import 'bulk_upload_body.dart';
import 'bulk_upload_footer.dart';
import 'bulk_upload_header.dart';

/// The dialog while files are being picked and sent (UI/UX guide §3.1):
/// header, the scrolling body, and the footer. [BulkUploadDialog] owns the
/// state and the leave guard and passes both down.
class BulkUploadEditor extends StatelessWidget {
  const BulkUploadEditor({
    super.key,
    required this.state,
    required this.counts,
    required this.cap,
    required this.isMobile,
    required this.onRequestClose,
    required this.onPick,
    required this.onDrop,
    required this.onClearAll,
    required this.onRemove,
    required this.onRetry,
    required this.onUnsupportedExpired,
    required this.onSend,
  });

  final BulkUploadState state;
  final BulkUploadCounts counts;

  /// 20, or the free receipts left on trial (S3, §9.3).
  final int cap;
  final bool isMobile;

  /// The leave check: true when the dialog closed, false when the user stayed.
  /// Also runs before "Upgrade now" navigates.
  final Future<bool> Function() onRequestClose;
  final VoidCallback onPick;
  final ValueChanged<List<web.File>> onDrop;
  final VoidCallback onClearAll;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRetry;
  final ValueChanged<int> onUnsupportedExpired;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BulkUploadHeader(
            validCount: counts.valid, cap: cap, onClose: onRequestClose),
        const SizedBox(height: 16),
        Flexible(
          fit: isMobile ? FlexFit.tight : FlexFit.loose,
          child: SingleChildScrollView(
            child: BulkUploadBody(
              state: state,
              counts: counts,
              cap: cap,
              onPick: onPick,
              onDrop: onDrop,
              onClearAll: onClearAll,
              onRemove: onRemove,
              onRetry: onRetry,
              onUnsupportedExpired: onUnsupportedExpired,
              onUpgrade: onRequestClose,
            ),
          ),
        ),
        const SizedBox(height: 16),
        BulkUploadFooter(
          help: footerHelpFor(counts),
          sendCount: counts.valid,
          canSend: bulkCanSendWithinCap(counts, cap),
          isSending: state.isSending,
          onCancel: onRequestClose,
          onSend: onSend,
        ),
      ],
    );
  }
}
