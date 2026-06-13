import 'dart:js_interop';
import 'dart:math' show max;
import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../models/expense_category.dart';
import '../models/expenses_analysis_detail_state.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../utils/format_utils.dart';

/// Handles all Excel export operations for the app.
/// Screens pass domain models; this service owns all workbook construction
/// and triggers the browser download.
class ExcelExportService {
  // ── style constants ────────────────────────────────────────────────────────
  static final _headerBg   = xl.ExcelColor.fromHexString('FF362B71');
  static final _totalBg    = xl.ExcelColor.fromHexString('FFE8E5F0');
  static final _white      = xl.ExcelColor.fromHexString('FFFFFFFF');
  static final _thinBorder = xl.Border(borderStyle: xl.BorderStyle.Thin);

  static xl.CellStyle _headerStyle() => xl.CellStyle(
        backgroundColorHex: _headerBg,
        fontColorHex: _white,
        bold: true,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  static xl.CellStyle _totalStyle() => xl.CellStyle(
        backgroundColorHex: _totalBg,
        bold: true,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  static xl.CellStyle _dataStyle() => xl.CellStyle(
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  // ── low-level helpers ──────────────────────────────────────────────────────
  static void _styleRow(
      xl.Sheet sheet, int rowIndex, int colCount, xl.CellStyle style) {
    for (var c = 0; c < colCount; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: rowIndex))
          .cellStyle = style;
    }
  }

  static void _autoWidths(xl.Sheet sheet, List<List<String>> rows) {
    final colCount =
        rows.isEmpty ? 0 : rows.map((r) => r.length).reduce(max);
    for (var c = 0; c < colCount; c++) {
      double maxLen = 0;
      for (final row in rows) {
        if (c < row.length) maxLen = max(maxLen, row[c].length.toDouble());
      }
      sheet.setColumnWidth(c, (maxLen + 4).clamp(10, 60));
    }
  }

  /// Downloads a remote URL as a file. Fetches the bytes, then triggers a
  /// browser blob download with the given [filename].
  static Future<void> downloadUrl(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    final contentType = response.headers['content-type'] ?? 'application/octet-stream';
    final blob = web.Blob(
      [response.bodyBytes.buffer.toJS].toJS,
      web.BlobPropertyBag(type: contentType),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = objectUrl;
    anchor.download = filename;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
  }

  /// Triggers a browser download of server-produced .xlsx bytes (e.g. the
  /// payments report endpoints, which build the workbook server-side).
  static void downloadXlsxBytes(List<int> bytes, String fileName) =>
      _download(bytes, fileName);

  static void _download(List<int> bytes, String fileName) {
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(
          type:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  // ── public exports ─────────────────────────────────────────────────────────

  /// Monthly breakdown — one row per cycle.
  static void exportMasterBreakdown(
    List<ExpensesAnalysisSummaryRow> rows,
    String locale,
  ) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    const headers = ['Cycle', 'Period', 'Total Approved'];
    const colCount = 3;

    final workbook = xl.Excel.createExcel();
    final sheet = workbook['Monthly Breakdown'];
    workbook.delete('Sheet1');

    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());
    _styleRow(sheet, 0, colCount, _headerStyle());

    final allRows = <List<String>>[headers];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final period =
          '${row.fromDate.toCompanyDate(locale)} – ${row.toDate.toCompanyDate(locale)}';
      sheet.appendRow([
        xl.TextCellValue(row.cycleLabel),
        xl.TextCellValue(period),
        xl.DoubleCellValue(row.totalApproved),
      ]);
      _styleRow(sheet, i + 1, colCount, _dataStyle());
      allRows.add([row.cycleLabel, period, row.totalApproved.toString()]);
    }

    _autoWidths(sheet, allRows);
    _download(workbook.encode()!, 'monthly-breakdown-$today.xlsx');
  }

  /// Pivot breakdown — employees × categories for a single cycle.
  static void exportDetailPivot(
    ExpensesAnalysisDetailState state,
    String locale,
  ) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final colCount = state.activeCategories.length + 2;

    final workbook = xl.Excel.createExcel();
    final sheet = workbook['Pivot'];
    workbook.delete('Sheet1');

    // Header row
    final headerLabels = <String>['By Employee'];
    for (final a in state.activeCategories) {
      final cat = ExpenseCategory.fromApiValue(a);
      headerLabels
          .add(locale == 'he' ? (cat?.hebrewLabel ?? a) : (cat?.englishLabel ?? a));
    }
    headerLabels.add('Total');

    sheet.appendRow(headerLabels.map((h) => xl.TextCellValue(h)).toList());
    _styleRow(sheet, 0, colCount, _headerStyle());

    // Data rows
    final allRows = <List<String>>[headerLabels];
    for (var i = 0; i < state.pivotRows.length; i++) {
      final row = state.pivotRows[i];
      sheet.appendRow([
        xl.TextCellValue(row.employeeName),
        ...state.activeCategories
            .map((a) => xl.DoubleCellValue(row.categoryTotals[a] ?? 0)),
        xl.DoubleCellValue(row.total),
      ]);
      _styleRow(sheet, i + 1, colCount, _dataStyle());
      allRows.add([
        row.employeeName,
        ...state.activeCategories
            .map((a) => (row.categoryTotals[a] ?? 0).toString()),
        row.total.toString(),
      ]);
    }

    // Grand total row
    final totalRowIndex = state.pivotRows.length + 1;
    sheet.appendRow([
      xl.TextCellValue('Total Approved'),
      ...state.activeCategories.map((a) {
        final colTotal = state.byCategory
            .where((c) => c.categoryAlias == a)
            .map((c) => c.total)
            .fold(0.0, (sum, v) => sum + v);
        return xl.DoubleCellValue(colTotal);
      }),
      xl.DoubleCellValue(state.grandTotal),
    ]);
    _styleRow(sheet, totalRowIndex, colCount, _totalStyle());

    _autoWidths(sheet, allRows);
    _download(workbook.encode()!, 'pivot-${state.cycleId}-$today.xlsx');
  }
}
