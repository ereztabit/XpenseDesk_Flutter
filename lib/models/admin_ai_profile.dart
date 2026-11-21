/// FS-1026 Receipt AI - AI profiles (docs/api-guides/receipt-ai-api-guide.md).
library;

import 'admin_ai_json.dart';


/// One row of `GET /api/admin/ai-profiles` (default first, then by number).
class AdminAiProfileRow {
  const AdminAiProfileRow({
    required this.aiProfileId,
    required this.name,
    this.description,
    required this.isDefault,
    required this.isArchived,
    this.publishedVersionNumber,
    this.publishedAt,
    this.draftVersionNumber,
    this.draftUpdatedAt,
    required this.companyCount,
    this.updatedAt,
    this.updatedByName,
  });

  final int aiProfileId;
  final String name;
  final String? description;
  final bool isDefault;
  final bool isArchived;
  final int? publishedVersionNumber;
  final DateTime? publishedAt;
  final int? draftVersionNumber;
  final DateTime? draftUpdatedAt;
  final int companyCount;
  final DateTime? updatedAt;
  final String? updatedByName;

  factory AdminAiProfileRow.fromJson(Map<String, dynamic> j) => AdminAiProfileRow(
        aiProfileId: adminAiInt(j['aiProfileId']) ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        isDefault: j['isDefault'] as bool? ?? false,
        isArchived: j['isArchived'] as bool? ?? false,
        publishedVersionNumber: adminAiInt(j['publishedVersionNumber']),
        publishedAt: adminAiUtc(j['publishedAt']),
        draftVersionNumber: adminAiInt(j['draftVersionNumber']),
        draftUpdatedAt: adminAiUtc(j['draftUpdatedAt']),
        companyCount: adminAiInt(j['companyCount']) ?? 0,
        updatedAt: adminAiUtc(j['updatedAt']),
        updatedByName: j['updatedByName'] as String?,
      );
}

/// One fixed Mistral field and the profile's instruction for it.
class AdminAiMistralField {
  const AdminAiMistralField({required this.name, required this.type, required this.instruction});

  final String name;

  /// `text` or `number`.
  final String type;
  final String instruction;

  factory AdminAiMistralField.fromJson(Map<String, dynamic> j) => AdminAiMistralField(
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
        instruction: j['instruction'] as String? ?? '',
      );
}

/// The text of one version (published or draft).
class AdminAiVersionText {
  const AdminAiVersionText({
    required this.versionNumber,
    required this.gptSystemPrompt,
    required this.gptUserPrompt,
    required this.mistralFields,
    required this.sourceId,
    this.sourceNote,
    required this.isBuiltIn,
    this.createdAt,
    this.updatedAt,
  });

  final int versionNumber;
  final String gptSystemPrompt;
  final String gptUserPrompt;
  final List<AdminAiMistralField> mistralFields;

  /// 1 Seed, 2 Edited, 3 Imported, 4 Restored, 5 Cloned.
  final int sourceId;
  final String? sourceNote;
  final bool isBuiltIn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, String> get fieldMap => {for (final f in mistralFields) f.name: f.instruction};

  factory AdminAiVersionText.fromJson(Map<String, dynamic> j) => AdminAiVersionText(
        versionNumber: adminAiInt(j['versionNumber']) ?? 0,
        gptSystemPrompt: j['gptSystemPrompt'] as String? ?? '',
        gptUserPrompt: j['gptUserPrompt'] as String? ?? '',
        mistralFields: (j['mistralFields'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminAiMistralField.fromJson)
            .toList(),
        sourceId: adminAiInt(j['sourceId']) ?? 0,
        sourceNote: j['sourceNote'] as String?,
        isBuiltIn: j['isBuiltIn'] as bool? ?? false,
        createdAt: adminAiUtc(j['createdAt']),
        updatedAt: adminAiUtc(j['updatedAt']),
      );
}

/// `GET /api/admin/ai-profiles/{id}`.
class AdminAiProfileDetail {
  const AdminAiProfileDetail({
    required this.aiProfileId,
    required this.name,
    this.description,
    required this.isDefault,
    required this.isArchived,
    required this.companyCount,
    this.published,
    this.draft,
    required this.todayToken,
  });

  final int aiProfileId;
  final String name;
  final String? description;
  final bool isDefault;
  final bool isArchived;
  final int companyCount;
  final AdminAiVersionText? published;
  final AdminAiVersionText? draft;
  final String todayToken;

  /// What the editors start from: the draft when there is one.
  AdminAiVersionText? get editable => draft ?? published;

  factory AdminAiProfileDetail.fromJson(Map<String, dynamic> j) => AdminAiProfileDetail(
        aiProfileId: adminAiInt(j['aiProfileId']) ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        isDefault: j['isDefault'] as bool? ?? false,
        isArchived: j['isArchived'] as bool? ?? false,
        companyCount: adminAiInt(j['companyCount']) ?? 0,
        published: j['published'] is Map<String, dynamic>
            ? AdminAiVersionText.fromJson(j['published'] as Map<String, dynamic>)
            : null,
        draft: j['draft'] is Map<String, dynamic>
            ? AdminAiVersionText.fromJson(j['draft'] as Map<String, dynamic>)
            : null,
        todayToken: j['todayToken'] as String? ?? '{{today}}',
      );
}

/// One row of `GET /api/admin/ai-profiles/{id}/versions` (newest first).
class AdminAiVersionItem {
  const AdminAiVersionItem({
    required this.versionNumber,
    required this.statusId,
    required this.sourceId,
    this.sourceNote,
    this.createdAt,
    this.updatedAt,
    this.updatedByName,
  });

  final int versionNumber;

  /// 1 Draft, 2 Published, 3 Previous.
  final int statusId;
  final int sourceId;
  final String? sourceNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedByName;

  factory AdminAiVersionItem.fromJson(Map<String, dynamic> j) => AdminAiVersionItem(
        versionNumber: adminAiInt(j['versionNumber']) ?? 0,
        statusId: adminAiInt(j['statusId']) ?? 3,
        sourceId: adminAiInt(j['sourceId']) ?? 0,
        sourceNote: j['sourceNote'] as String?,
        createdAt: adminAiUtc(j['createdAt']),
        updatedAt: adminAiUtc(j['updatedAt']),
        updatedByName: j['updatedByName'] as String?,
      );
}
