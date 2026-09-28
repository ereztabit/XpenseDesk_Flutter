import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_validation_utils.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../expenses/receipt_upload_zone.dart';
import '../web_file_drop_region.dart';

/// Where files enter the dialog (UI/UX guide §3.2): a compact dashed drop row
/// on desktop, a full-width "Choose receipts" button on mobile (phones can't
/// drag files in, so there is no drag copy there).
class BulkUploadDropZone extends StatelessWidget {
  const BulkUploadDropZone({
    super.key,
    required this.onPick,
    required this.onDrop,
  });

  final VoidCallback onPick;
  final ValueChanged<List<web.File>> onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const hintStyle = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: l10n.bulkUploadChooseReceipts,
            variant: AppButtonVariant.normal,
            icon: Icons.upload_file,
            onPressed: onPick,
          ),
          const SizedBox(height: 6),
          Text(l10n.bulkUploadHint,
              textAlign: TextAlign.center, style: hintStyle),
        ],
      );
    }

    return WebFileDropRegion(
      allowedExtensions: kBulkUploadExtensions,
      onFiles: onDrop,
      builder: (context, isDragOver) => Semantics(
        button: true,
        label: l10n.bulkUploadChoose,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            foregroundPainter: DashedBorderPainter(
              color: isDragOver ? AppTheme.primary : AppTheme.borderMedium,
              strokeWidth: isDragOver ? 2 : 1.5,
              borderRadius: 10,
            ),
            child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            // Centres the row vertically in the box; without it the content
            // sat at the top edge.
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDragOver ? AppTheme.primaryTint : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
            ),
            // Full width, so spaceBetween still pushes the hint to the end
            // once the alignment above loosens the constraints.
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file,
                        size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.bulkUploadDrag,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    AppButton(
                      label: l10n.bulkUploadChoose,
                      variant: AppButtonVariant.normal,
                      dense: true,
                      onPressed: onPick,
                    ),
                  ],
                ),
                Text(l10n.bulkUploadHint, style: hintStyle),
              ],
            ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
