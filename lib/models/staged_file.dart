/// A file parked in the server's staging area (POST /api/bulk-uploads/files).
///
/// [stagedFileId] is the file's SHA-256 plus its extension, so an identical
/// file always gets the identical id — it is what the batch is sent with.
class StagedFile {
  final String stagedFileId;
  final String originalFileName;
  final int fileSizeBytes;

  const StagedFile({
    required this.stagedFileId,
    required this.originalFileName,
    required this.fileSizeBytes,
  });

  factory StagedFile.fromJson(Map<String, dynamic> json) {
    return StagedFile(
      stagedFileId: json['stagedFileId'] as String? ?? '',
      originalFileName: json['originalFileName'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
