import '../utils/api_date_utils.dart';

/// One file inside a sent batch (GET /api/bulk-uploads, api-guide §6).
class BulkUploadItem {
  final String itemId;
  final String originalFileName;

  /// `Queued` | `Processing` | `Created` | `ActionRequired` | `Unreadable`.
  final String status;

  /// Set once the file became an expense: Created or ActionRequired.
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

  /// The file is now an expense on My expenses — a normal one, or (S2) one
  /// flagged Action Required.
  bool get isFiled =>
      (status == 'Created' || status == 'ActionRequired') && expenseId != null;
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

  /// Files filed as Action Required expenses (S2).
  final int actionRequiredCount;
  final int unreadableCount;
  final int pendingCount;
  final List<BulkUploadItem> items;

  /// FS-1025: the budget the batch files into; null = the sender's Monthly
  /// sheet (older payloads carry neither field).
  final String? expenseSheetId;

  /// `Monthly` | `PettyCash`, when the server sends it.
  final String? sheetType;

  const BulkUploadBatch({
    required this.batchId,
    required this.status,
    required this.submittedAt,
    this.completedAt,
    required this.totalCount,
    required this.createdCount,
    this.actionRequiredCount = 0,
    required this.unreadableCount,
    required this.pendingCount,
    this.items = const [],
    this.expenseSheetId,
    this.sheetType,
  });

  /// Filed into a budget, not the Monthly sheet.
  bool get isBudget => expenseSheetId != null && sheetType != 'Monthly';

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
      actionRequiredCount:
          (json['actionRequiredCount'] as num?)?.toInt() ?? 0,
      unreadableCount: (json['unreadableCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BulkUploadItem.fromJson)
              .toList() ??
          const [],
      expenseSheetId: json['expenseSheetId'] as String?,
      sheetType: json['sheetType'] as String?,
    );
  }
}
