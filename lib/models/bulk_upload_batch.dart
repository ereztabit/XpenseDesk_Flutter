import '../utils/api_date_utils.dart';

/// One file inside a sent batch (GET /api/bulk-uploads, api-guide §6).
class BulkUploadItem {
  final String itemId;
  final String originalFileName;

  /// `Queued` | `Processing` | `Created` | `Unreadable`.
  final String status;
  final String? expenseId;

  /// A flat `ApiErrorCodes` name for an Unreadable item — never display text.
  final String? failureCode;

  const BulkUploadItem({
    required this.itemId,
    required this.originalFileName,
    required this.status,
    this.expenseId,
    this.failureCode,
  });

  factory BulkUploadItem.fromJson(Map<String, dynamic> json) {
    return BulkUploadItem(
      itemId: json['itemId'] as String? ?? '',
      originalFileName: json['originalFileName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expenseId: json['expenseId'] as String?,
      failureCode: json['failureCode'] as String?,
    );
  }
}

/// A sent batch as the notifications panel reads it (api-guide §6).
class BulkUploadBatch {
  final String batchId;

  /// `Submitted` | `Completed`.
  final String status;
  final DateTime submittedAt;
  final DateTime? completedAt;
  final int totalCount;
  final int createdCount;
  final int unreadableCount;
  final int pendingCount;
  final List<BulkUploadItem> items;

  const BulkUploadBatch({
    required this.batchId,
    required this.status,
    required this.submittedAt,
    this.completedAt,
    required this.totalCount,
    required this.createdCount,
    required this.unreadableCount,
    required this.pendingCount,
    this.items = const [],
  });

  bool get isCompleted => status == 'Completed';

  /// Files the worker has finished with, whatever the outcome.
  int get doneCount => (totalCount - pendingCount).clamp(0, totalCount);

  /// When the batch last changed state — what "new since last open" and the
  /// card's timestamp are measured against.
  DateTime get lastEventAt => completedAt ?? submittedAt;

  factory BulkUploadBatch.fromJson(Map<String, dynamic> json) {
    return BulkUploadBatch(
      batchId: json['batchId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submittedAt: parseApiUtc(json['submittedAt'] as String?) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      completedAt: parseApiUtc(json['completedAt'] as String?),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      createdCount: (json['createdCount'] as num?)?.toInt() ?? 0,
      unreadableCount: (json['unreadableCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BulkUploadItem.fromJson)
              .toList() ??
          const [],
    );
  }
}
