import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/bulk_upload_file_entry.dart';
import 'pdf_utils.dart';

/// Limits shared by the client checks and the dialog (UI/UX guide §10). The
/// server repeats every one of them (api-guide §4.1).
const int kBulkUploadMaxFiles = 20;
const int kBulkUploadMaxBytes = 10 * 1024 * 1024;
const int kBulkUploadMinImageSide = 300;
const int kBulkUploadMaxConcurrentUploads = 3;
const List<String> kBulkUploadExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];

/// True for `.jpg` `.jpeg` `.png` `.pdf`, case-insensitive. Anything else is
/// auto-removed from the dialog rather than listed (§4, check 1).
bool isBulkUploadSupportedType(String fileName) {
  final name = fileName.toLowerCase();
  return kBulkUploadExtensions.any(name.endsWith);
}

bool isPdfFileName(String fileName) =>
    fileName.toLowerCase().endsWith('.pdf');

/// Runs the content checks on one supported-type file, in the guide's order
/// (§4): size, empty/corrupt, too small, multi-page. The duplicate check comes
/// first but needs the rest of the list, so the caller owns it.
///
/// Returns null when the file may be uploaded.
Future<BulkUploadRejection?> validateBulkUploadFile(
  Uint8List bytes, {
  required bool isPdf,
}) async {
  if (bytes.length > kBulkUploadMaxBytes) return BulkUploadRejection.tooLarge;
  if (bytes.isEmpty) return BulkUploadRejection.corrupt;

  if (isPdf) {
    // null = "could not tell" (see pdfPageCount): let the server judge it
    // rather than refuse a receipt the user legitimately picked.
    final pages = await pdfPageCount(bytes);
    if (pages != null && pages > 1) return BulkUploadRejection.multiPage;
    return null;
  }

  final side = await _shortestImageSide(bytes);
  if (side == null) return BulkUploadRejection.corrupt;
  if (side < kBulkUploadMinImageSide) return BulkUploadRejection.tooSmall;
  return null;
}

/// Decodes the first frame only for its dimensions. Null when the bytes are
/// not an image the browser can decode.
Future<int?> _shortestImageSide(Uint8List bytes) async {
  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final side = image.width < image.height ? image.width : image.height;
    image.dispose();
    return side;
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
  }
}

/// The identity two files are compared on: the content hash, or — when the
/// browser could not hash — the hash half of the server's `stagedFileId`.
String? contentKeyOf(BulkUploadFileEntry entry) {
  if (entry.contentHash != null) return entry.contentHash;
  final staged = entry.stagedFileId;
  if (staged == null) return null;
  final dot = staged.indexOf('.');
  return (dot < 0 ? staged : staged.substring(0, dot)).toLowerCase();
}

/// True when [key] matches a file already in [others].
bool isDuplicateOf(String? key, Iterable<BulkUploadFileEntry> others) =>
    key != null && others.any((o) => contentKeyOf(o) == key);

/// Builds the list entry for one supported-type file: duplicate first, then
/// the content checks (§4). The 20-file cap is the caller's, since it depends
/// on the list at the moment the entry is appended.
Future<BulkUploadFileEntry> buildBulkUploadEntry({
  required int localId,
  required String fileName,
  required Uint8List bytes,
  required String? contentHash,
  required Iterable<BulkUploadFileEntry> existing,
}) async {
  final isPdf = isPdfFileName(fileName);
  final rejection = isDuplicateOf(contentHash, existing)
      ? BulkUploadRejection.duplicate
      : await validateBulkUploadFile(bytes, isPdf: isPdf);

  return BulkUploadFileEntry(
    localId: localId,
    fileName: fileName,
    sizeBytes: bytes.length,
    isPdf: isPdf,
    bytes: bytes,
    contentHash: contentHash,
    state: rejection == null
        ? BulkUploadFileState.waiting
        : BulkUploadFileState.rejected,
    rejection: rejection,
  );
}

/// Maps a server staging refusal (api-guide §4.2) onto the client rejection it
/// matches, so both render the same. Null for codes that are not a per-file
/// rule — the caller treats those as a failed upload.
BulkUploadRejection? rejectionFromErrorCode(String? errorCode) {
  switch (errorCode) {
    case 'BulkUploadFileTypeNotSupported':
      return BulkUploadRejection.unsupportedType;
    case 'BulkUploadFileEmpty':
    case 'BulkUploadFileCorrupt':
      return BulkUploadRejection.corrupt;
    case 'BulkUploadFileTooLarge':
      return BulkUploadRejection.tooLarge;
    case 'BulkUploadFileTooSmall':
      return BulkUploadRejection.tooSmall;
    case 'MultiPageReceiptNotSupported':
      return BulkUploadRejection.multiPage;
    default:
      return null;
  }
}
