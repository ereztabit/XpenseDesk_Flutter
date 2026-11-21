/// FS-1026: `GET /api/admin/ai-usage/scans/{expenseId}` - one AI-read expense
/// for review.
library;

import 'admin_ai_json.dart';


/// The five reviewable values (plus VAT, read-only).
class AdminAiScanValues {
  const AdminAiScanValues({
    this.merchant,
    this.date,
    this.amount,
    this.currency,
    this.taxAmount,
    this.receiptNumber,
  });

  final String? merchant;

  /// `yyyy-MM-dd`.
  final String? date;
  final double? amount;
  final String? currency;
  final double? taxAmount;
  final String? receiptNumber;

  static AdminAiScanValues? maybe(Object? v) =>
      v is Map<String, dynamic> ? AdminAiScanValues.fromJson(v) : null;

  factory AdminAiScanValues.fromJson(Map<String, dynamic> j) => AdminAiScanValues(
        merchant: j['merchant'] as String?,
        date: j['date'] as String?,
        amount: (j['amount'] as num?)?.toDouble(),
        currency: j['currency'] as String?,
        taxAmount: (j['taxAmount'] as num?)?.toDouble(),
        receiptNumber: j['receiptNumber'] as String?,
      );
}

/// One model call of the scan (from the scan record).
class AdminAiModelResult {
  const AdminAiModelResult({this.step, this.model, required this.durationMs, this.reason, this.values});

  /// `ai-scan` (first model) or `ai-escalation` (GPT).
  final String? step;
  final String? model;
  final int durationMs;
  final String? reason;
  final AdminAiScanValues? values;

  /// By model name, not by step: a GPT-only scan has a single escalation step
  /// with a GPT model. Any other name (the dev qa-mock reader) counts as Mistral.
  bool get isGpt => (model ?? '').toLowerCase().startsWith('gpt');

  factory AdminAiModelResult.fromJson(Map<String, dynamic> j) => AdminAiModelResult(
        step: j['step'] as String?,
        model: j['model'] as String?,
        durationMs: adminAiInt(j['durationMs']) ?? 0,
        reason: j['reason'] as String?,
        values: AdminAiScanValues.maybe(j['values']),
      );
}

class AdminAiScanReview {
  const AdminAiScanReview({
    required this.expenseId,
    required this.companyId,
    required this.companyName,
    this.baseCurrencyCode,
    this.createdAt,
    this.scannedAt,
    this.totalDurationMs,
    this.aiProfileId,
    this.aiProfileName,
    this.aiProfileVersionNumber,
    this.aiModel,
    this.aiReviewStatusId,
    this.aiReviewedAt,
    this.aiReviewedByName,
    required this.isClosed,
    required this.isForeign,
    this.originalImageUrl,
    this.processedImageUrl,
    this.originalInfo,
    this.processedInfo,
    this.aiResult,
    required this.modelResults,
    required this.expense,
    this.scanRecord,
  });

  final String expenseId;
  final String companyId;
  final String companyName;
  final String? baseCurrencyCode;
  final DateTime? createdAt;
  final DateTime? scannedAt;
  final int? totalDurationMs;
  final int? aiProfileId;
  final String? aiProfileName;
  final int? aiProfileVersionNumber;
  final String? aiModel;
  final int? aiReviewStatusId;
  final DateTime? aiReviewedAt;
  final String? aiReviewedByName;

  /// Its owner can no longer edit it - amount and currency are locked.
  final bool isClosed;
  final bool isForeign;
  final String? originalImageUrl;
  final String? processedImageUrl;
  final String? originalInfo;
  final String? processedInfo;
  final AdminAiScanValues? aiResult;
  final List<AdminAiModelResult> modelResults;
  final AdminAiScanValues expense;
  final Map<String, dynamic>? scanRecord;

  AdminAiModelResult? get mistral => modelResults.where((m) => !m.isGpt).firstOrNull;
  AdminAiModelResult? get gpt => modelResults.where((m) => m.isGpt).firstOrNull;

  factory AdminAiScanReview.fromJson(Map<String, dynamic> j) => AdminAiScanReview(
        expenseId: j['expenseId'] as String? ?? '',
        companyId: j['companyId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        baseCurrencyCode: j['baseCurrencyCode'] as String?,
        createdAt: adminAiUtc(j['createdAt']),
        scannedAt: adminAiUtc(j['scannedAt']),
        totalDurationMs: adminAiInt(j['totalDurationMs']),
        aiProfileId: adminAiInt(j['aiProfileId']),
        aiProfileName: j['aiProfileName'] as String?,
        aiProfileVersionNumber: adminAiInt(j['aiProfileVersionNumber']),
        aiModel: j['aiModel'] as String?,
        aiReviewStatusId: adminAiInt(j['aiReviewStatusId']),
        aiReviewedAt: adminAiUtc(j['aiReviewedAt']),
        aiReviewedByName: j['aiReviewedByName'] as String?,
        isClosed: j['isClosed'] as bool? ?? false,
        isForeign: j['isForeign'] as bool? ?? false,
        originalImageUrl: j['originalImageUrl'] as String?,
        processedImageUrl: j['processedImageUrl'] as String?,
        originalInfo: j['originalInfo'] as String?,
        processedInfo: j['processedInfo'] as String?,
        aiResult: AdminAiScanValues.maybe(j['aiResult']),
        modelResults: (j['modelResults'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminAiModelResult.fromJson)
            .toList(),
        expense: AdminAiScanValues.maybe(j['expense']) ?? const AdminAiScanValues(),
        scanRecord: j['scanRecord'] is Map<String, dynamic> ? j['scanRecord'] as Map<String, dynamic> : null,
      );
}
