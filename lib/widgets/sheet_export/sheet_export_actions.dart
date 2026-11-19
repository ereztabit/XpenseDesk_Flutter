import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/sheet_export_provider.dart';
import '../../services/api_service.dart';
import '../../services/excel_export_service.dart';
import '../../services/sheet_export_service.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_export_copy_utils.dart';
import '../../utils/sheet_export_utils.dart';
import '../app_button.dart';
import '../payments/excel_download_icon.dart';

/// PC-5: "Download as PDF" / "Download as Excel" for an approved sheet
/// (Monthly or budget). The caller shows it only when the sheet is Approved.
/// Each button spins on its own; a failure is a localized SnackBar.
/// Side by side, never full width (owner QA, 2026-11-19): standard size from
/// 600px; on a phone compact "PDF" / "Excel", centred on one line.
class SheetExportActions extends ConsumerStatefulWidget {
  const SheetExportActions({super.key, required this.sheetId, this.inRow = false});

  final String sheetId;

  /// Placed inside a Row (the mobile back row, FS-1025 #12): shrink to fit
  /// instead of centring across the full width.
  final bool inRow;

  @override
  ConsumerState<SheetExportActions> createState() => _SheetExportActionsState();
}

class _SheetExportActionsState extends ConsumerState<SheetExportActions> {
  SheetExportFormat? _busy;

  Future<void> _download(SheetExportFormat format) async {
    if (_busy != null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = format);
    try {
      final file = await ref.read(sheetExportServiceProvider).download(widget.sheetId, format);
      ExcelExportService.downloadBytes(file.bytes, file.fileName, format.mimeType);
    } on UnauthorizedException {
      // ApiService already sends the user to sign in.
    } on SheetExportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(sheetExportErrorText(l10n, e.errorCode))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericErrorRetry)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _button(AppLocalizations l10n, SheetExportFormat format, {required bool compact}) {
    final loading = _busy == format;
    final button = AppButton(
      label: format == SheetExportFormat.pdf
          ? (compact ? l10n.sheetExportPdfShort : l10n.sheetExportPdf)
          : (compact ? l10n.sheetExportExcelShort : l10n.sheetExportExcel),
      variant: AppButtonVariant.normal,
      dense: compact,
      icon: format == SheetExportFormat.pdf ? Icons.picture_as_pdf_outlined : null,
      // The glyph's badge overhangs its size: fit it in the PDF icon's 16px
      // box so both buttons are the same height (owner QA, 2026-11-19).
      iconWidget: format == SheetExportFormat.excel
          ? const SizedBox.square(
              dimension: 16,
              child: FittedBox(child: ExcelDownloadIcon(size: 16)),
            )
          : null,
      isLoading: loading,
      onPressed: _busy == null ? () => _download(format) : null,
    );
    // Always mounted (empty when idle) so the button keeps its parent while it spins.
    return Tooltip(message: loading ? l10n.sheetExportPreparing : '', child: button);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Phone: the compact size keeps both on one line (owner QA, 2026-11-19).
    final compact = context.isNarrow;
    final pdf = _button(l10n, SheetExportFormat.pdf, compact: compact);
    final excel = _button(l10n, SheetExportFormat.excel, compact: compact);
    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.center : WrapAlignment.start,
      children: [pdf, excel],
    );
    // Phone: centred across the card (owner QA, 2026-11-19).
    return compact && !widget.inRow ? SizedBox(width: double.infinity, child: buttons) : buttons;
  }
}
