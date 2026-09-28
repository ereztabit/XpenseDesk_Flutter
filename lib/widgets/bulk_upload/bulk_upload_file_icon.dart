import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// File-type icon instead of a preview (receipts all look alike, §3.4): a
/// muted image icon for JPG/PNG, a destructive-coloured PDF icon for PDF.
class BulkUploadFileIcon extends StatelessWidget {
  const BulkUploadFileIcon({super.key, required this.isPdf});

  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      size: 20,
      color: isPdf ? AppTheme.destructive : AppTheme.mutedForeground,
    );
  }
}
