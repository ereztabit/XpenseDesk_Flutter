import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/free_receipts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/free_receipts_utils.dart';

/// "12 of 20 free receipts left" over a thin bar that fills as receipts are
/// used (UI/UX guide §9.2). Amber for the last 2. Renders nothing when no limit
/// applies (a paid plan), so it can sit anywhere unconditionally.
///
/// [width] fixes the meter's width (compact placements); null fills the
/// parent's width. [padding] is applied only when the meter shows, so a
/// placement's spacing disappears with it.
class FreeReceiptsMeter extends ConsumerWidget {
  const FreeReceiptsMeter({
    super.key,
    this.width,
    this.padding = EdgeInsets.zero,
  });

  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final freeReceipts = ref.watch(currentFreeReceiptsProvider);
    if (!freeReceipts.isLimited) return const SizedBox.shrink();

    final low = freeReceipts.isLow;

    final meter = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          freeReceiptsLeftText(l10n, freeReceipts),
          style: TextStyle(
            fontSize: 12,
            fontWeight: low ? FontWeight.w500 : FontWeight.w400,
            color: low ? AppTheme.amber : AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: freeReceipts.usedFraction,
            minHeight: 6,
            backgroundColor: AppTheme.muted,
            valueColor: AlwaysStoppedAnimation<Color>(
                low ? AppTheme.amber : AppTheme.primary),
          ),
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: width == null ? meter : SizedBox(width: width, child: meter),
    );
  }
}
