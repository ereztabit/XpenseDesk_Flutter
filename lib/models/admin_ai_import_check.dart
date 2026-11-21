/// FS-1026: `POST /api/admin/ai-profiles/{id}/import/check` - what an uploaded
/// ReceiptLab file would do, before anything is written.
class AdminAiImportCheck {
  const AdminAiImportCheck({
    required this.canImport,
    this.errorCode,
    required this.hasSystemPrompt,
    required this.hasUserPrompt,
    required this.hasTodayToken,
    required this.mistralFieldsInFile,
    required this.unknownFields,
    required this.fieldsMissingFromPrompt,
    required this.comparedWith,
    this.comparedVersionNumber,
    required this.gptChanged,
    required this.mistralFieldsChanged,
    required this.replacesDraft,
  });

  final bool canImport;
  final String? errorCode;
  final bool hasSystemPrompt;
  final bool hasUserPrompt;
  final bool hasTodayToken;
  final List<String> mistralFieldsInFile;
  final List<String> unknownFields;
  final List<String> fieldsMissingFromPrompt;

  /// `draft` or `published`.
  final String comparedWith;
  final int? comparedVersionNumber;
  final bool gptChanged;
  final List<String> mistralFieldsChanged;
  final bool replacesDraft;

  static List<String> _list(Object? v) =>
      (v as List<dynamic>? ?? const []).whereType<String>().toList();

  factory AdminAiImportCheck.fromJson(Map<String, dynamic> j) => AdminAiImportCheck(
        canImport: j['canImport'] as bool? ?? false,
        errorCode: j['errorCode'] as String?,
        hasSystemPrompt: j['hasSystemPrompt'] as bool? ?? false,
        hasUserPrompt: j['hasUserPrompt'] as bool? ?? false,
        hasTodayToken: j['hasTodayToken'] as bool? ?? false,
        mistralFieldsInFile: _list(j['mistralFieldsInFile']),
        unknownFields: _list(j['unknownFields']),
        fieldsMissingFromPrompt: _list(j['fieldsMissingFromPrompt']),
        comparedWith: j['comparedWith'] as String? ?? 'published',
        comparedVersionNumber: (j['comparedVersionNumber'] as num?)?.toInt(),
        gptChanged: j['gptChanged'] as bool? ?? false,
        mistralFieldsChanged: _list(j['mistralFieldsChanged']),
        replacesDraft: j['replacesDraft'] as bool? ?? false,
      );
}

/// `GET /api/admin/ai-profiles/{id}/file` - a profile as a ReceiptLab file.
class AdminAiProfileFile {
  const AdminAiProfileFile({required this.fileName, required this.content});

  final String fileName;
  final String content;

  factory AdminAiProfileFile.fromJson(Map<String, dynamic> j) => AdminAiProfileFile(
        fileName: j['fileName'] as String? ?? 'profile.txt',
        content: j['content'] as String? ?? '',
      );
}
