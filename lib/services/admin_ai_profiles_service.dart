import '../models/admin_ai_import_check.dart';
import '../models/admin_ai_profile.dart';
import 'admin_ai_api.dart';

/// FS-1026: Receipt AI profiles (`/api/admin/ai-profiles`). Platform admin only.
/// docs/api-guides/receipt-ai-api-guide.md
class AdminAiProfilesService {
  AdminAiProfilesService({AdminAiApi? api}) : _api = api ?? AdminAiApi();

  final AdminAiApi _api;
  static const _base = '/api/admin/ai-profiles';

  Future<List<AdminAiProfileRow>> getProfiles() async =>
      AdminAiApi.list(await _api.get(_base)).map(AdminAiProfileRow.fromJson).toList();

  Future<AdminAiProfileRow> createProfile({
    required String name,
    String? description,
    required int fromAiProfileId,
  }) async =>
      AdminAiProfileRow.fromJson(AdminAiApi.map(await _api.post(_base, {
        'name': name,
        'description': description,
        'fromAiProfileId': fromAiProfileId,
      })));

  Future<AdminAiProfileDetail> getProfile(int id) async =>
      AdminAiProfileDetail.fromJson(AdminAiApi.map(await _api.get('$_base/$id')));

  /// Returns the draft's version number.
  Future<int> saveDraft(
    int id, {
    required String systemPrompt,
    required String userPrompt,
    required Map<String, String> mistralFields,
  }) async =>
      _versionNumber(await _api.put('$_base/$id/draft', {
        'gptSystemPrompt': systemPrompt,
        'gptUserPrompt': userPrompt,
        'mistralFields': mistralFields,
      }), 'draftVersionNumber');

  Future<void> discardDraft(int id) => _api.delete('$_base/$id/draft');

  /// Returns the published version number.
  Future<int> publish(int id) async =>
      _versionNumber(await _api.post('$_base/$id/publish'), 'publishedVersionNumber');

  Future<AdminAiImportCheck> checkImport(int id, {required String fileName, required String content}) async =>
      AdminAiImportCheck.fromJson(AdminAiApi.map(
          await _api.post('$_base/$id/import/check', {'fileName': fileName, 'content': content})));

  Future<int> importFile(int id, {required String fileName, required String content}) async =>
      _versionNumber(await _api.post('$_base/$id/import', {'fileName': fileName, 'content': content}),
          'draftVersionNumber');

  Future<AdminAiProfileFile> downloadFile(int id, {bool draft = false}) async =>
      AdminAiProfileFile.fromJson(
          AdminAiApi.map(await _api.get('$_base/$id/file', query: {'draft': '$draft'})));

  Future<List<AdminAiVersionItem>> getVersions(int id) async =>
      AdminAiApi.list(await _api.get('$_base/$id/versions')).map(AdminAiVersionItem.fromJson).toList();

  Future<int> restoreVersion(int id, int versionNumber) async =>
      _versionNumber(await _api.post('$_base/$id/versions/$versionNumber/restore'), 'draftVersionNumber');

  Future<void> setDefault(int id) => _api.post('$_base/$id/default');

  Future<void> archive(int id) => _api.post('$_base/$id/archive');

  Future<void> restore(int id) => _api.post('$_base/$id/restore');

  static int _versionNumber(Object? data, String key) =>
      (AdminAiApi.map(data)[key] as num?)?.toInt() ?? 0;
}
