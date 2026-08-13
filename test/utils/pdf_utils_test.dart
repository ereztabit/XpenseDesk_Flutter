// Page counting is the whole basis for declining a multi-page receipt upload,
// so it is pinned by tests: a wrong count either refuses a receipt the user
// legitimately picked, or lets a batch scan through to be read as page 1.
//
// Fixtures in test/fixtures/ are real Chrome print-to-PDF output (plain page
// dictionaries, uncompressed xref table). The compressed case is built in
// memory by [_objectStreamPdf] below — a PDF 1.5 whose catalog and page tree
// live inside a Flate-compressed object stream, which is what Word, Acrobat
// and Ghostscript emit. In that file the bytes "/Type /Pages" and "/Count"
// appear nowhere in the clear, so it is the case a byte scan cannot read.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/pdf_utils.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

void main() {
  group('pdfPageCount', () {
    test('counts a single-page PDF', () async {
      expect(await pdfPageCount(_fixture('receipt_one_page.pdf')), 1);
    });

    test('counts a multi-page PDF', () async {
      expect(await pdfPageCount(_fixture('receipt_three_pages.pdf')), 3);
    });

    test('counts pages when the page tree is in a compressed object stream',
        () async {
      final bytes = _objectStreamPdf(pageCount: 3);
      // Guard the guard: if these markers ever became visible the fixture would
      // no longer be testing the compressed path.
      final raw = latin1.decode(bytes);
      expect(raw.contains('/Type /Pages'), isFalse);
      expect(raw.contains('/Count'), isFalse);

      expect(await pdfPageCount(bytes), 3);
    });

    test('returns null for bytes that are not a PDF', () async {
      final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0]);
      expect(await pdfPageCount(png), isNull);
    });

    test('returns null for a truncated PDF', () async {
      final full = _fixture('receipt_three_pages.pdf');
      final half = Uint8List.sublistView(full, 0, full.length ~/ 2);
      expect(await pdfPageCount(half), isNull);
    });

    test('returns null for empty bytes', () async {
      expect(await pdfPageCount(Uint8List(0)), isNull);
    });
  });
}

/// Builds a PDF 1.5 with [pageCount] pages whose catalog and page tree sit
/// inside a Flate-compressed object stream, indexed by a cross-reference
/// stream — the modern layout that hides the page tree from raw byte scans.
Uint8List _objectStreamPdf({required int pageCount}) {
  final kids =
      List.generate(pageCount, (i) => '${i + 3} 0 R').join(' ');
  final objects = <int, String>{
    1: '<< /Type /Catalog /Pages 2 0 R >>',
    2: '<< /Type /Pages /Kids [$kids] /Count $pageCount >>',
    for (var i = 0; i < pageCount; i++)
      i + 3: '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] >>',
  };

  final header = StringBuffer();
  final bodies = <String>[];
  var offset = 0;
  for (final entry in objects.entries) {
    header.write('${entry.key} $offset ');
    bodies.add(entry.value);
    offset += entry.value.length + 1;
  }
  final headerStr = header.toString();
  final objStm = Uint8List.fromList(
    zlib.encode(ascii.encode('$headerStr${bodies.join('\n')}\n')),
  );

  final out = BytesBuilder();
  void write(String s) => out.add(latin1.encode(s));

  write('%PDF-1.5\n%âãÏÓ\n');

  final objStmNumber = objects.length + 1;
  final objStmOffset = out.length;
  write('$objStmNumber 0 obj\n<< /Type /ObjStm /N ${objects.length} '
      '/First ${headerStr.length} /Filter /FlateDecode '
      '/Length ${objStm.length} >>\nstream\n');
  out.add(objStm);
  write('\nendstream\nendobj\n');

  final xrefNumber = objStmNumber + 1;
  final xrefOffset = out.length;
  final rows = BytesBuilder();
  void row(int type, int f2, int f3) {
    rows.addByte(type);
    rows.add([
      (f2 >> 24) & 0xff,
      (f2 >> 16) & 0xff,
      (f2 >> 8) & 0xff,
      f2 & 0xff,
    ]);
    rows.add([(f3 >> 8) & 0xff, f3 & 0xff]);
  }

  row(0, 0, 65535);
  var indexInStream = 0;
  for (final _ in objects.keys) {
    row(2, objStmNumber, indexInStream++);
  }
  row(1, objStmOffset, 0);
  row(1, xrefOffset, 0);
  final xref = Uint8List.fromList(zlib.encode(rows.toBytes()));

  write('$xrefNumber 0 obj\n<< /Type /XRef /Size ${xrefNumber + 1} '
      '/W [1 4 2] /Root 1 0 R /Filter /FlateDecode '
      '/Length ${xref.length} >>\nstream\n');
  out.add(xref);
  write('\nendstream\nendobj\n');
  write('startxref\n$xrefOffset\n%%EOF\n');

  return out.toBytes();
}
