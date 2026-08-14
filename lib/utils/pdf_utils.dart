import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';

/// How many pages the PDF in [bytes] has, or `null` when the bytes cannot be
/// parsed as a PDF at all (corrupt, truncated, encrypted, or not a PDF).
///
/// A receipt upload must be a single page: the AI scan reads one receipt per
/// file, so a multi-page PDF is declined before it is sent (see
/// docs/bugs/completed/multipage-pdf-decline-and-ask-user-to-split-pages.md).
///
/// `null` means "we could not tell", never "one page" — callers must let an
/// unreadable file through to the server rather than refuse a receipt the user
/// legitimately picked. The server is the authoritative check.
///
/// Reads the real page tree (not a byte scan), so it is also correct for PDFs
/// that keep their page tree inside a compressed object stream — which is what
/// Word, Acrobat and Ghostscript emit.
Future<int?> pdfPageCount(Uint8List bytes) async {
  try {
    final document = await PDFParser(ByteStream(bytes)).parse();
    final catalog = await document.catalog;
    final pages = await catalog.getPages();
    return pages.pageCount;
  } catch (_) {
    return null;
  }
}
