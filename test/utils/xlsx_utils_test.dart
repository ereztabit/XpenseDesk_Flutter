import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/xlsx_utils.dart';

const _setup = '<pageSetup orientation="landscape" fitToWidth="1" fitToHeight="1"/>';
const _pr = '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>';

void main() {
  group('worksheetPrintSetup', () {
    test('adds sheetPr first and pageSetup after pageMargins', () {
      expect(
        worksheetPrintSetup('<worksheet a="1"><sheetData/><pageMargins left="0.7"/><headerFooter/></worksheet>'),
        '<worksheet a="1">$_pr<sheetData/><pageMargins left="0.7"/>$_setup<headerFooter/></worksheet>',
      );
    });

    test('without pageMargins: pageSetup before the first later element', () {
      expect(
        worksheetPrintSetup('<worksheet><sheetData/><drawing r:id="x"/></worksheet>'),
        '<worksheet>$_pr<sheetData/>$_setup<drawing r:id="x"/></worksheet>',
      );
    });

    test('existing pageSetup and sheetPr are completed, not duplicated', () {
      expect(
        worksheetPrintSetup('<worksheet><sheetPr><tabColor rgb="FF0000"/></sheetPr>'
            '<pageSetup orientation="portrait" paperSize="9"/></worksheet>'),
        '<worksheet><sheetPr><tabColor rgb="FF0000"/><pageSetUpPr fitToPage="1"/></sheetPr>'
        '<pageSetup orientation="landscape" paperSize="9" fitToWidth="1" fitToHeight="1"/></worksheet>',
      );
      expect(
        worksheetPrintSetup('<worksheet><sheetPr codeName="S"/><sheetData/></worksheet>'),
        '<worksheet><sheetPr codeName="S"><pageSetUpPr fitToPage="1"/></sheetPr><sheetData/>$_setup</worksheet>',
      );
      expect(
        worksheetPrintSetup('<worksheet><sheetPr><pageSetUpPr fitToPage="0"/></sheetPr></worksheet>'),
        '<worksheet><sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>$_setup</worksheet>',
      );
    });

    test('prefixed XML (as ClosedXML writes it) keeps its prefix', () {
      final out = worksheetPrintSetup('<x:worksheet><x:sheetData/><x:pageMargins left="0.7"/></x:worksheet>');
      expect(out, startsWith('<x:worksheet><x:sheetPr><x:pageSetUpPr fitToPage="1"/></x:sheetPr>'));
      expect(out, contains('<x:pageMargins left="0.7"/><x:pageSetup orientation="landscape" fitToWidth="1" fitToHeight="1"/>'));
      expect(out, endsWith('</x:worksheet>'));
    });
  });

  test('xlsxPrintSetup: every worksheet of a real workbook prints landscape on one page', () {
    final book = xl.Excel.createExcel();
    book['Sheet1'].appendRow([xl.TextCellValue('a')]);
    book['Other'].appendRow([xl.TextCellValue('b')]);

    final patched = xlsxPrintSetup(book.encode()!);

    final sheets = ZipDecoder()
        .decodeBytes(patched)
        .files
        .where((f) => f.name.startsWith('xl/worksheets/') && f.name.endsWith('.xml'))
        .map((f) => utf8.decode(f.content as List<int>))
        .toList();
    expect(sheets, hasLength(2));
    for (final s in sheets) {
      expect('orientation="landscape"'.allMatches(s), hasLength(1));
      expect('fitToPage="1"'.allMatches(s), hasLength(1));
      expect(s, contains('fitToWidth="1"'));
      expect(s, contains('fitToHeight="1"'));
    }
    // Still a workbook the package can read back.
    expect(xl.Excel.decodeBytes(patched).tables.keys, containsAll(['Sheet1', 'Other']));
  });
}
