import 'dart:convert';

import 'package:archive/archive.dart';

/// Every Excel file the app builds prints landscape, "Fit Sheet on One Page"
/// (owner, 2026-11-19). The `excel` package has no page setup, so the saved
/// .xlsx (a zip) gets it written into each worksheet.
List<int> xlsxPrintSetup(List<int> bytes) {
  final source = ZipDecoder().decodeBytes(bytes);
  final out = Archive();
  for (final file in source.files) {
    if (file.isFile && _isWorksheet(file.name)) {
      final xml = utf8.decode(file.content as List<int>);
      final patched = utf8.encode(worksheetPrintSetup(xml));
      out.addFile(ArchiveFile(file.name, patched.length, patched));
    } else {
      out.addFile(file);
    }
  }
  return ZipEncoder().encode(out)!;
}

bool _isWorksheet(String name) =>
    name.startsWith('xl/worksheets/') && name.endsWith('.xml');

// Schema order: sheetPr is the worksheet's first child; pageSetup follows
// pageMargins and precedes headerFooter, drawing, tableParts and the rest.
// Tags may carry a namespace prefix (`<x:pageMargins/>`); added tags take the
// document's prefix.
final _worksheetOpen = RegExp(r'<(\w+:)?worksheet\b[^>]*>');
final _sheetPr = RegExp(r'<(\w+:)?sheetPr\b([^>]*?)(/?)>');
final _pageSetUpPr = RegExp(r'<(\w+:)?pageSetUpPr\b[^>]*/>');
final _existing = RegExp(r'<(\w+:)?pageSetup\b[^>]*/>');
final _margins = RegExp(r'<(\w+:)?pageMargins\b[^>]*/>');
final _after = RegExp(
  r'<(\w+:)?(headerFooter|rowBreaks|colBreaks|customProperties|cellWatches|'
  r'ignoredErrors|smartTags|drawing|legacyDrawing|legacyDrawingHF|picture|'
  r'oleObjects|controls|webPublishItems|tableParts|extLst)\b|</(\w+:)?worksheet>',
);

const _setupAttrs = 'orientation="landscape" fitToWidth="1" fitToHeight="1"';

String _setAttr(String tag, String name, String value) =>
    tag.contains('$name=')
        ? tag.replaceFirst(RegExp('$name="[^"]*"'), '$name="$value"')
        : tag.replaceFirst(RegExp(r'\s*/>$'), ' $name="$value"/>');

/// One worksheet's XML set to print landscape, fitted to one page.
String worksheetPrintSetup(String xml) => _withFitToPage(_withPageSetup(xml));

String _withPageSetup(String xml) {
  final existing = _existing.firstMatch(xml);
  if (existing != null) {
    var tag = existing.group(0)!;
    tag = _setAttr(tag, 'orientation', 'landscape');
    tag = _setAttr(tag, 'fitToWidth', '1');
    tag = _setAttr(tag, 'fitToHeight', '1');
    return xml.replaceRange(existing.start, existing.end, tag);
  }
  final margins = _margins.firstMatch(xml);
  if (margins != null) {
    final tag = '<${margins.group(1) ?? ''}pageSetup $_setupAttrs/>';
    return xml.replaceRange(margins.end, margins.end, tag);
  }
  final after = _after.firstMatch(xml);
  if (after == null) return xml; // not a worksheet we understand: leave it
  final tag = '<${after.group(1) ?? after.group(3) ?? ''}pageSetup $_setupAttrs/>';
  return xml.replaceRange(after.start, after.start, tag);
}

// Excel applies fitToWidth / fitToHeight only when sheetPr says fitToPage.
String _withFitToPage(String xml) {
  final open = _worksheetOpen.firstMatch(xml);
  if (open == null) return xml;
  final p = open.group(1) ?? '';
  final pr = _sheetPr.firstMatch(xml);
  if (pr == null) {
    final tag = '<${p}sheetPr><${p}pageSetUpPr fitToPage="1"/></${p}sheetPr>';
    return xml.replaceRange(open.end, open.end, tag);
  }
  final setUp = _pageSetUpPr.firstMatch(xml);
  if (setUp != null) {
    return xml.replaceRange(setUp.start, setUp.end, _setAttr(setUp.group(0)!, 'fitToPage', '1'));
  }
  final child = '<${p}pageSetUpPr fitToPage="1"/>';
  if (pr.group(3) == '/') {
    // <sheetPr .../> - open it up to hold the child.
    return xml.replaceRange(pr.start, pr.end, '<${p}sheetPr${pr.group(2)}>$child</${p}sheetPr>');
  }
  // pageSetUpPr follows tabColor / outlinePr: insert before </sheetPr>.
  final close = xml.indexOf('</${p}sheetPr>', pr.end);
  return close < 0 ? xml : xml.replaceRange(close, close, child);
}
