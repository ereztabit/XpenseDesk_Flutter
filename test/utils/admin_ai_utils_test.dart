// FS-1026 Receipt AI - list rules: order, status, archive/default, accuracy,
// model chains, company filter, usage filter query.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_ai_profile.dart';
import 'package:xpensedesk_flutter/models/admin_ai_usage.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_utils.dart';

AdminAiProfileRow _p(int id, {bool isDefault = false, bool archived = false, int companies = 0}) => AdminAiProfileRow(
  aiProfileId: id,
  name: 'P$id',
  isDefault: isDefault,
  isArchived: archived,
  companyCount: companies,
);

AdminAiCompanyRow _c(String name, int? profileId) =>
    AdminAiCompanyRow(companyId: name, companyName: name, isActive: true, aiProfileId: profileId, aiScanCount: 0);

void main() {
  group('profile list', () {
    test('the default is first, then by number', () {
      final rows = sortAiProfiles([_p(3), _p(1), _p(2, isDefault: true)]);
      expect(rows.map((r) => r.aiProfileId), [2, 1, 3]);
    });

    test('archived profiles are hidden unless asked for', () {
      final rows = [_p(1, isDefault: true), _p(2, archived: true)];
      expect(visibleAiProfiles(rows, showArchived: false).map((r) => r.aiProfileId), [1]);
      expect(visibleAiProfiles(rows, showArchived: true).map((r) => r.aiProfileId), [1, 2]);
      expect(activeAiProfiles(rows).map((r) => r.aiProfileId), [1]);
    });

    test('status: archived, default, in use, not in use', () {
      expect(aiProfileStatus(_p(1, isDefault: true, companies: 5)), AdminAiProfileStatus.isDefault);
      expect(aiProfileStatus(_p(2, companies: 2)), AdminAiProfileStatus.inUse);
      expect(aiProfileStatus(_p(3)), AdminAiProfileStatus.notInUse);
      expect(aiProfileStatus(_p(4, archived: true, companies: 1)), AdminAiProfileStatus.archived);
    });

    test('archive is blocked for the default and for a profile with companies', () {
      expect(aiArchiveBlock(_p(1, isDefault: true)), AdminAiArchiveBlock.isDefault);
      expect(aiArchiveBlock(_p(2, companies: 1)), AdminAiArchiveBlock.hasCompanies);
      expect(aiArchiveBlock(_p(3)), isNull);
    });

    test('set as default only for an active non-default profile', () {
      expect(canSetAiDefault(_p(1, isDefault: true)), isFalse);
      expect(canSetAiDefault(_p(2, archived: true)), isFalse);
      expect(canSetAiDefault(_p(3)), isTrue);
    });
  });

  group('usage', () {
    test('accuracy is verified over reviewed, null when nothing reviewed', () {
      expect(aiAccuracyPercent(0, 0), isNull);
      expect(aiAccuracyPercent(20, 6), 77);
      expect(aiAccuracyPercent(5, 0), 100);
      expect(aiAccuracyPercent(0, 3), 0);
    });

    test('model chains map to the three paths', () {
      expect(aiModelKind('mistral-document-ai-2512'), AdminAiModelKind.mistral);
      expect(aiModelKind('mistral-document-ai-2512>gpt-5-mini'), AdminAiModelKind.mistralThenGpt);
      expect(aiModelKind('gpt-5-mini'), AdminAiModelKind.gptOnly);
      expect(aiModelKind(null), AdminAiModelKind.unknown);
      expect(aiModelKind('qa-mock'), AdminAiModelKind.other);
    });

    test('filters become query parameters, empty ones left out', () {
      expect(AdminAiUsageFilters.none.toQuery(), isEmpty);
      expect(AdminAiUsageFilters.none.isEmpty, isTrue);
      final f = AdminAiUsageFilters.none
          .withCompany('c1')
          .withProfile(2)
          .withDates(DateTime(2026, 11, 1), DateTime(2026, 11, 21));
      expect(f.toQuery(), {'companyId': 'c1', 'profileId': '2', 'from': '2026-11-01', 'to': '2026-11-21'});
      expect(f.withCompany(null).toQuery().containsKey('companyId'), isFalse);
    });
  });

  test('companies filter by name and by profile', () {
    final rows = [_c('Harbor Logistics', 2), _c('Cedar Field', 2), _c('Blue Olive', 1)];
    expect(filterAiCompanies(rows, query: 'har').map((c) => c.companyName), ['Harbor Logistics']);
    expect(filterAiCompanies(rows, profileId: 2).length, 2);
    expect(filterAiCompanies(rows, query: 'olive', profileId: 2), isEmpty);
    expect(filterAiCompanies(rows).length, 3);
  });
}
