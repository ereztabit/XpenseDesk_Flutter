import 'dart:typed_data';

/// Where one picked file is in the bulk dialog (UI/UX guide §3.5).
enum BulkUploadFileState {
  /// Failed a client check or was refused by the server. Never uploaded
  /// again, never counts toward the 20, never blocks sending.
  rejected,

  /// Valid, queued behind the three concurrent uploads.
  waiting,
  uploading,
  uploaded,

  /// Network or 5xx failure — blocks sending until retried or removed.
  failed,
}

/// Client-side reasons a file is rejected. The server's own refusals arrive as
/// flat `ApiErrorCodes` names and are mapped onto the same values, so a server
/// refusal and a client one show identically.
enum BulkUploadRejection {
  duplicate,
  tooLarge,
  corrupt,
  tooSmall,
  multiPage,
  unsupportedType,
}

/// One file in the dialog's list. Immutable: every change is a [copyWith].
class BulkUploadFileEntry {
  /// Local id, stable for the dialog's lifetime (file names can repeat).
  final int localId;
  final String fileName;
  final int sizeBytes;
  final bool isPdf;
  final Uint8List bytes;

  /// Lower-case SHA-256 hex of [bytes]; null when hashing was not possible.
  final String? contentHash;

  final BulkUploadFileState state;
  final BulkUploadRejection? rejection;

  /// 0.0–1.0 while [BulkUploadFileState.uploading].
  final double progress;

  /// Set once the staging call succeeds.
  final String? stagedFileId;

  const BulkUploadFileEntry({
    required this.localId,
    required this.fileName,
    required this.sizeBytes,
    required this.isPdf,
    required this.bytes,
    required this.contentHash,
    required this.state,
    this.rejection,
    this.progress = 0,
    this.stagedFileId,
  });

  bool get isRejected => state == BulkUploadFileState.rejected;

  /// Counts toward the 20-file cap and the "valid" total.
  bool get isValid => !isRejected;

  BulkUploadFileEntry copyWith({
    BulkUploadFileState? state,
    BulkUploadRejection? rejection,
    double? progress,
    String? stagedFileId,
  }) {
    return BulkUploadFileEntry(
      localId: localId,
      fileName: fileName,
      sizeBytes: sizeBytes,
      isPdf: isPdf,
      bytes: bytes,
      contentHash: contentHash,
      state: state ?? this.state,
      rejection: rejection ?? this.rejection,
      progress: progress ?? this.progress,
      stagedFileId: stagedFileId ?? this.stagedFileId,
    );
  }
}
