import 'dart:convert';

import 'package:archive/archive.dart';

/// Every Excel file the app builds prints landscape (owner, 2026-11-19). The
/// `excel` package has no page setup, so the saved .xlsx (a zip) gets a
/// `<pageSetup orientation="landscape"/>` in each worksheet.
List<int> xlsxLandscape(List<int> bytes) {
  final source = ZipDecoder().decodeBytes(bytes);
  final out = Archive();
  for (final file in source.files) {
    if (file.isFile && _isWorksheet(file.name)) {
      final xml = utf8.decode(file.content as List<int>);
      final patched = utf8.encode(worksheetLandscape(xml));
      out.addFile(ArchiveFile(file.name, patched.length, patched));
    } else {
      out.addFile(file);
    }
  }
  return ZipEncoder().encode(out)!;
}

bool _isWorksheet(String name) =>
    name.startsWith('xl/worksheets/') && name.endsWith('.xml');

// Schema order: pageSetup follows pageMargins and precedes headerFooter,
// drawing, tableParts and the rest. Tags may carry a namespace prefix
// (`<x:pageMargins/>`); the inserted tag takes the document's prefix.
final _existing = RegExp(r'<(\w+:)?pageSetup\b[^>]*/>');
final _margins = RegExp(r'<(\w+:)?pageMargins\b[^>]*/>');
final _after = RegExp(
  r'<(\w+:)?(headerFooter|rowBreaks|colBreaks|customProperties|cellWatches|'
  r'ignoredErrors|smartTags|drawing|legacyDrawing|legacyDrawingHF|picture|'
  r'oleObjects|controls|webPublishItems|tableParts|extLst)\b|</(\w+:)?worksheet>',
);

String _landscape(String? prefix) =>
    '<${prefix ?? ''}pageSetup orientation="landscape"/>';

/// One worksheet's XML with landscape page setup.
String worksheetLandscape(String xml) {
  final existing = _existing.firstMatch(xml);
  if (existing != null) {
    final tag = existing.group(0)!;
    final fixed = tag.contains('orientation=')
        ? tag.replaceFirst(RegExp(r'orientation="[^"]*"'), 'orientation="landscape"')
        : tag.replaceFirst('pageSetup', 'pageSetup orientation="landscape"');
    return xml.replaceRange(existing.start, existing.end, fixed);
  }
  final margins = _margins.firstMatch(xml);
  if (margins != null) {
    return xml.replaceRange(margins.end, margins.end, _landscape(margins.group(1)));
  }
  final after = _after.firstMatch(xml);
  if (after == null) return xml; // not a worksheet we understand: leave it
  final tag = _landscape(after.group(1) ?? after.group(3));
  return xml.replaceRange(after.start, after.start, tag);
}
