import 'package:flutter/material.dart';

import '../../models/bulk_upload_file_entry.dart';
import '../../utils/responsive_utils.dart';
import 'bulk_upload_file_card.dart';
import 'bulk_upload_file_row.dart';

/// The dialog's files: a card grid on desktop, list rows on mobile (UI/UX
/// guide §1.1). Numbered 1..N in list order, so a removal renumbers.
///
/// The grid's column count follows the available width and every card has
/// the same fixed height — equal heights without `IntrinsicHeight`, which
/// this codebase avoids (sub-pixel overflow stripes under dart2js, CR Rule 6).
class BulkUploadFileList extends StatelessWidget {
  const BulkUploadFileList({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onRetry,
  });

  final List<BulkUploadFileEntry> files;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRetry;

  static const double _gap = 10;
  static const double _minCardWidth = 150;

  /// One height for every card: header (with a Remove button when
  /// rejected), two name lines, size and a two-line status fit without
  /// overflow at [_minCardWidth].
  static const double _cardHeight = 152;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < files.length; i++)
            BulkUploadFileRow(
              key: ValueKey(files[i].localId),
              number: i + 1,
              entry: files[i],
              onRemove: () => onRemove(files[i].localId),
              onRetry: () => onRetry(files[i].localId),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // As many columns as fit at [_minCardWidth]; the cards then stretch to
        // share the row. Floored so rounding never wraps the last card.
        final perRow = ((constraints.maxWidth + _gap) / (_minCardWidth + _gap))
            .floor()
            .clamp(1, 6);
        final width =
            ((constraints.maxWidth - _gap * (perRow - 1)) / perRow)
                .floorToDouble();
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < files.length; i++)
              SizedBox(
                key: ValueKey(files[i].localId),
                width: width,
                child: BulkUploadFileCard(
                  number: i + 1,
                  entry: files[i],
                  height: _cardHeight,
                  onRemove: () => onRemove(files[i].localId),
                  onRetry: () => onRetry(files[i].localId),
                ),
              ),
          ],
        );
      },
    );
  }
}
