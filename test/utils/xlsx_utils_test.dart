import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/xlsx_utils.dart';

void main() {
  group('worksheetLandscape', () {
    test('adds pageSetup right after pageMargins', () {
      const xml = '<worksheet><sheetData/><pageMargins left="0.7"/>'
          '<headerFooter/></worksheet>';
      expect(
        worksheetLandscape(xml),
        '<worksheet><sheetData/><pageMargins left="0.7"/>'
        '<pageSetup orientation="landscape"/><headerFooter/></worksheet>',
      );
    });

    test('without pageMargins: before the first later element', () {
      expect(
        worksheetLandscape('<worksheet><sheetData/><drawing r:id="x"/></worksheet>'),
        '<worksheet><sheetData/><pageSetup orientation="landscape"/>'
        '<drawing r:id="x"/></worksheet>',
      );
    });

    test('prefixed XML (as ClosedXML writes it) keeps its prefix and stays well-formed', () {
      expect(
        worksheetLandscape('<x:worksheet><x:sheetData/><x:pageMargins left="0.7"/></x:worksheet>'),
        '<x:worksheet><x:sheetData/><x:pageMargins left="0.7"/>'
        '<x:pageSetup orientation="landscape"/></x:worksheet>',
      );
      expect(
        worksheetLandscape('<x:worksheet><x:sheetData/></x:worksheet>'),
        '<x:worksheet><x:sheetData/><x:pageSetup orientation="landscape"/></x:worksheet>',
      );
      expect(
        worksheetLandscape('<x:worksheet><x:pageSetup paperSize="9"/></x:worksheet>'),
        '<x:worksheet><x:pageSetup orientation="landscape" paperSize="9"/></x:worksheet>',
      );
    });

    test('an existing pageSetup is switched, not duplicated', () {
      expect(
        worksheetLandscape('<worksheet><pageSetup orientation="portrait" paperSize="9"/></worksheet>'),
        '<worksheet><pageSetup orientation="landscape" paperSize="9"/></worksheet>',
      );
      expect(
        worksheetLandscape('<worksheet><pageSetup paperSize="9"/></worksheet>'),
        '<worksheet><pageSetup orientation="landscape" paperSize="9"/></worksheet>',
      );
    });
  });

  test('xlsxLandscape: every worksheet of a real workbook prints landscape', () {
    final book = xl.Excel.createExcel();
    book['Sheet1'].appendRow([xl.TextCellValue('a')]);
    book['Other'].appendRow([xl.TextCellValue('b')]);

    final patched = xlsxLandscape(book.encode()!);

    final sheets = ZipDecoder()
        .decodeBytes(patched)
        .files
        .where((f) => f.name.startsWith('xl/worksheets/') && f.name.endsWith('.xml'))
        .map((f) => utf8.decode(f.content as List<int>))
        .toList();
    expect(sheets, hasLength(2));
    for (final s in sheets) {
      expect('orientation="landscape"'.allMatches(s), hasLength(1));
    }
    // Still a workbook the package can read back.
    expect(xl.Excel.decodeBytes(patched).tables.keys, containsAll(['Sheet1', 'Other']));
  });
}
