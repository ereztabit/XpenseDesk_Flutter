import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../../utils/free_receipts_utils.dart';
import '../error_alert.dart';
import '../free_receipts/free_receipts_callout.dart';
import 'bulk_upload_amber_notice.dart';
import 'bulk_upload_drop_zone.dart';
import 'bulk_upload_file_list.dart';
import 'bulk_upload_toolbar.dart';
import 'bulk_upload_unsupported_notice.dart';

/// The scrolling middle of the dialog (UI/UX guide §3.1, items 2–5): drop
/// zone, notices, toolbar, files, and a send error when there is one.
class BulkUploadBody extends StatelessWidget {
  const BulkUploadBody({
    super.key,
    required this.state,
    required this.counts,
    required this.cap,
    required this.onPick,
    required this.onDrop,
    required this.onClearAll,
    required this.onRemove,
    required this.onRetry,
    required this.onUnsupportedExpired,
    required this.onUpgrade,
  });

  final BulkUploadState state;
  final BulkUploadCounts counts;

  /// 20, or the free receipts left on trial (S3): below 20 the limit shows as
  /// the free-receipts callout instead of the plain notice (§9.3).
  final int cap;

  /// Closes the dialog before "Upgrade now" navigates; false keeps it open.
  final Future<bool> Function() onUpgrade;
  final VoidCallback onPick;
  final ValueChanged<List<web.File>> onDrop;
  final VoidCallback onClearAll;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRetry;
  final ValueChanged<int> onUnsupportedExpired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sendError = state.sendError;
    const gap = SizedBox(height: 12);
    final overFreeReceipts = bulkOverFreeReceipts(
        cap: cap, limitReached: state.limitReached, validCount: counts.valid);
    final usedUpRefusal = sendError == BulkUploadSendError.freeReceiptsUsedUp;
    // A "not enough" refusal says no more than the callout above it.
    final notEnoughShown = overFreeReceipts &&
        sendError == BulkUploadSendError.freeReceiptsNotEnough;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BulkUploadDropZone(onPick: onPick, onDrop: onDrop),
        if (state.unsupportedNames.isNotEmpty) ...[
          gap,
          BulkUploadUnsupportedNotice(
            key: ValueKey(state.unsupportedNoticeId),
            names: state.unsupportedNames,
            onExpired: () => onUnsupportedExpired(state.unsupportedNoticeId),
          ),
        ],
        // One free-receipts callout at most: "Only N left" once the list is
        // at or over what is left (on an add, or because the count dropped
        // meanwhile), or "used up" when that is what the send was refused for.
        if (usedUpRefusal || overFreeReceipts) ...[
          gap,
          FreeReceiptsCallout(
            onlyLeft: !usedUpRefusal && cap > 0 ? cap : null,
            onUpgrade: onUpgrade,
          ),
        ] else if (state.limitReached) ...[
          gap,
          BulkUploadAmberNotice(message: l10n.bulkUploadLimit, showIcon: true),
        ],
        if (sendError != null && !usedUpRefusal && !notEnoughShown) ...[
          gap,
          ErrorAlert(message: sendErrorText(l10n, sendError)),
        ],
        if (state.files.isNotEmpty) ...[
          gap,
          BulkUploadToolbar(counts: counts, onClearAll: onClearAll),
          const SizedBox(height: 8),
          BulkUploadFileList(
            files: state.files,
            onRemove: onRemove,
            onRetry: onRetry,
          ),
        ],
        if (counts.allRejected)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.bulkUploadAllRejected,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.mutedForeground),
            ),
          ),
      ],
    );
  }
}
