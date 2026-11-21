/// FS-1026 Receipt AI - companies per profile and usage
/// (docs/api-guides/receipt-ai-api-guide.md).
library;

import 'admin_ai_json.dart';


/// One row of `GET /api/admin/ai-profiles/companies`.
class AdminAiCompanyRow {
  const AdminAiCompanyRow({
    required this.companyId,
    required this.companyName,
    required this.isActive,
    this.aiProfileId,
    this.aiProfileName,
    this.publishedVersionNumber,
    this.onProfileSince,
    required this.aiScanCount,
  });

  final String companyId;
  final String companyName;
  final bool isActive;
  final int? aiProfileId;
  final String? aiProfileName;
  final int? publishedVersionNumber;
  final DateTime? onProfileSince;
  final int aiScanCount;

  factory AdminAiCompanyRow.fromJson(Map<String, dynamic> j) => AdminAiCompanyRow(
        companyId: j['companyId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        isActive: j['isActive'] as bool? ?? true,
        aiProfileId: adminAiInt(j['aiProfileId']),
        aiProfileName: j['aiProfileName'] as String?,
        publishedVersionNumber: adminAiInt(j['publishedVersionNumber']),
        onProfileSince: adminAiUtc(j['onProfileSince']),
        aiScanCount: adminAiInt(j['aiScanCount']) ?? 0,
      );
}

/// How the Usage table is grouped.
enum AdminAiGroupBy {
  model('model'),
  profile('profile');

  const AdminAiGroupBy(this.apiValue);
  final String apiValue;
}

/// One row of `GET /api/admin/ai-usage`.
class AdminAiUsageRow {
  const AdminAiUsageRow({
    this.key,
    this.aiProfileId,
    this.aiProfileName,
    required this.uploads,
    required this.verified,
    required this.corrected,
    required this.notReviewed,
  });

  /// Model chain or profile number; null = scanned before tracking.
  final String? key;
  final int? aiProfileId;
  final String? aiProfileName;
  final int uploads;
  final int verified;
  final int corrected;
  final int notReviewed;

  factory AdminAiUsageRow.fromJson(Map<String, dynamic> j) => AdminAiUsageRow(
        key: j['key'] as String?,
        aiProfileId: adminAiInt(j['aiProfileId']),
        aiProfileName: j['aiProfileName'] as String?,
        uploads: adminAiInt(j['uploads']) ?? 0,
        verified: adminAiInt(j['verified']) ?? 0,
        corrected: adminAiInt(j['corrected']) ?? 0,
        notReviewed: adminAiInt(j['notReviewed']) ?? 0,
      );
}

class AdminAiUsage {
  const AdminAiUsage({required this.total, required this.rows});

  final int total;
  final List<AdminAiUsageRow> rows;

  factory AdminAiUsage.fromJson(Map<String, dynamic> j) => AdminAiUsage(
        total: adminAiInt(j['total']) ?? 0,
        rows: (j['rows'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminAiUsageRow.fromJson)
            .toList(),
      );
}

/// One row of `GET /api/admin/ai-usage/scans`.
class AdminAiScanRow {
  const AdminAiScanRow({
    required this.expenseId,
    required this.companyId,
    required this.companyName,
    this.expenseDate,
    this.merchantName,
    this.amount,
    this.baseCurrencyCode,
    this.aiProfileId,
    this.aiProfileName,
    this.aiProfileVersionNumber,
    this.aiModel,
    this.aiReviewStatusId,
  });

  final String expenseId;
  final String companyId;
  final String companyName;
  final DateTime? expenseDate;
  final String? merchantName;
  final double? amount;
  final String? baseCurrencyCode;
  final int? aiProfileId;
  final String? aiProfileName;
  final int? aiProfileVersionNumber;
  final String? aiModel;

  /// null not reviewed, 1 Verified, 2 Corrected.
  final int? aiReviewStatusId;

  factory AdminAiScanRow.fromJson(Map<String, dynamic> j) => AdminAiScanRow(
        expenseId: j['expenseId'] as String? ?? '',
        companyId: j['companyId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        expenseDate: adminAiDayValue(j['expenseDate']),
        merchantName: j['merchantName'] as String?,
        amount: (j['amount'] as num?)?.toDouble(),
        baseCurrencyCode: j['baseCurrencyCode'] as String?,
        aiProfileId: adminAiInt(j['aiProfileId']),
        aiProfileName: j['aiProfileName'] as String?,
        aiProfileVersionNumber: adminAiInt(j['aiProfileVersionNumber']),
        aiModel: j['aiModel'] as String?,
        aiReviewStatusId: adminAiInt(j['aiReviewStatusId']),
      );
}
