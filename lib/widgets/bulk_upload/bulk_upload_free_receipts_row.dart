import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/free_receipts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/free_receipts_utils.dart';
import '../free_receipts/free_receipts_meter.dart';

/// The bulk dialog header's third row on trial (UI/UX guide §4.1, §9.3): the
/// compact free-receipts meter and "This batch will use 7". Renders nothing
/// when no limit applies.
class BulkUploadFreeReceiptsRow extends ConsumerWidget {
  const BulkUploadFreeReceiptsRow({super.key, required this.batchCount});

  /// The files that would be sent now — what the batch will use.
  final int batchCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.watch(currentFreeReceiptsProvider).isLimited) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          const FreeReceiptsMeter(width: 192),
          Text(
            freeReceiptsBatchUseText(l10n, batchCount),
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }
}
