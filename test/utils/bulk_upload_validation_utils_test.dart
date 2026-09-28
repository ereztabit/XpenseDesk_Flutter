// Bulk upload (FS-1007) client checks, run before any upload (UI/UX guide §4).
// A wrong verdict either refuses a legitimate receipt or uploads one the
// server will only refuse after the user waited for it.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_file_entry.dart';
import 'package:xpensedesk_flutter/utils/bulk_upload_validation_utils.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint(),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

BulkUploadFileEntry _entry({String? hash, String? staged}) =>
    BulkUploadFileEntry(
      localId: 1,
      fileName: 'a.jpg',
      sizeBytes: 1,
      isPdf: false,
      bytes: Uint8List(1),
      contentHash: hash,
      state: BulkUploadFileState.uploaded,
      stagedFileId: staged,
    );

void main() {
  group('isBulkUploadSupportedType', () {
    test('accepts jpg/jpeg/png/pdf in any case', () {
      for (final n in ['a.jpg', 'b.JPEG', 'c.Png', 'd.PDF']) {
        expect(isBulkUploadSupportedType(n), isTrue, reason: n);
      }
    });

    test('refuses anything else', () {
      for (final n in ['notes.docx', 'photo.heic', 'pdf', 'x.pdf.exe']) {
        expect(isBulkUploadSupportedType(n), isFalse, reason: n);
      }
    });
  });

  group('validateBulkUploadFile', () {
    test('an empty file is corrupt', () async {
      expect(await validateBulkUploadFile(Uint8List(0), isPdf: false),
          BulkUploadRejection.corrupt);
    });

    test('over 10 MB is too large, before anything is decoded', () async {
      expect(
        await validateBulkUploadFile(Uint8List(kBulkUploadMaxBytes + 1),
            isPdf: false),
        BulkUploadRejection.tooLarge,
      );
    });

    test('bytes that are not an image are corrupt', () async {
      expect(
        await validateBulkUploadFile(Uint8List.fromList([1, 2, 3, 4]),
            isPdf: false),
        BulkUploadRejection.corrupt,
      );
    });

    testWidgets('an image with a short side under 300 px is too small',
        (tester) async {
      await tester.runAsync(() async {
        expect(await validateBulkUploadFile(await _png(800, 299), isPdf: false),
            BulkUploadRejection.tooSmall);
        expect(await validateBulkUploadFile(await _png(300, 300), isPdf: false),
            isNull);
      });
    });

    test('a single-page PDF passes, a multi-page one does not', () async {
      expect(
        await validateBulkUploadFile(_fixture('receipt_one_page.pdf'),
            isPdf: true),
        isNull,
      );
      expect(
        await validateBulkUploadFile(_fixture('receipt_three_pages.pdf'),
            isPdf: true),
        BulkUploadRejection.multiPage,
      );
    });

    test('an unparseable PDF is let through for the server to judge',
        () async {
      expect(
        await validateBulkUploadFile(Uint8List.fromList([1, 2, 3]),
            isPdf: true),
        isNull,
      );
    });
  });

  group('duplicates', () {
    test('matches on content hash', () {
      expect(isDuplicateOf('abc', [_entry(hash: 'abc')]), isTrue);
      expect(isDuplicateOf('abc', [_entry(hash: 'def')]), isFalse);
    });

    test('falls back to the hash half of the staged id', () {
      final e = _entry(staged: 'ABC.jpg');
      expect(contentKeyOf(e), 'abc');
      expect(isDuplicateOf('abc', [e]), isTrue);
    });

    test('an unknown key never matches', () {
      expect(isDuplicateOf(null, [_entry()]), isFalse);
    });
  });

  test('rejectionFromErrorCode maps each staging refusal', () {
    expect(rejectionFromErrorCode('BulkUploadFileTypeNotSupported'),
        BulkUploadRejection.unsupportedType);
    expect(rejectionFromErrorCode('BulkUploadFileEmpty'),
        BulkUploadRejection.corrupt);
    expect(rejectionFromErrorCode('BulkUploadFileCorrupt'),
        BulkUploadRejection.corrupt);
    expect(rejectionFromErrorCode('BulkUploadFileTooLarge'),
        BulkUploadRejection.tooLarge);
    expect(rejectionFromErrorCode('BulkUploadFileTooSmall'),
        BulkUploadRejection.tooSmall);
    expect(rejectionFromErrorCode('MultiPageReceiptNotSupported'),
        BulkUploadRejection.multiPage);
    expect(rejectionFromErrorCode('BulkUploadNotEnabled'), isNull);
  });
}
