// FS-1026 CR fixes: locked fields on a closed foreign expense, draft changes,
// counts, the capped name list, UTC timestamps, safe image links.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_ai_json.dart';
import 'package:xpensedesk_flutter/models/admin_ai_profile.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_review_utils.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_utils.dart';

AdminAiVersionText _v(int n, String user, Map<String, String> fields) => AdminAiVersionText(
  versionNumber: n,
  gptSystemPrompt: 's',
  gptUserPrompt: user,
  mistralFields: [for (final e in fields.entries) AdminAiMistralField(name: e.key, type: 'text', instruction: e.value)],
  sourceId: 2,
  isBuiltIn: false,
);

void main() {
  test('closed locks money; closed foreign also locks the date', () {
    expect(aiLockedFields(isClosed: false, isForeign: true), isEmpty);
    expect(aiLockedFields(isClosed: true, isForeign: false), {AdminAiField.amount, AdminAiField.currency});
    expect(aiLockedFields(isClosed: true, isForeign: true), {
      AdminAiField.amount,
      AdminAiField.currency,
      AdminAiField.date,
    });

    const expense = AdminAiScanValues(merchant: 'A', date: '2026-11-12', amount: 10, currency: 'USD');
    final form = AdminAiReviewForm(expense)..values[AdminAiField.date] = '2026-11-11';
    expect(form.canSave(isClosed: true), isTrue);
    expect(form.canSave(isClosed: true, isForeign: true), isFalse);
    expect(form.canSave(isClosed: false, isForeign: true), isTrue);
  });

  test('draft changes against the published version', () {
    final detail = AdminAiProfileDetail(
      aiProfileId: 2,
      name: 'P',
      isDefault: false,
      isArchived: false,
      companyCount: 1,
      todayToken: '{{today}}',
      published: _v(3, 'u', {'date': 'a', 'amount': 'b'}),
      draft: _v(4, 'u2', {'date': 'a2', 'amount': 'b'}),
    );
    final changes = aiDraftChanges(detail);
    expect(changes.gptChanged, isTrue);
    expect(changes.fields, {'date'});
  });

  test('unreviewed count and the capped name list', () {
    expect(aiUnreviewedCount(['a', 'b', 'c'], {'b'}), 2);
    final first = aiFirstItems(List.generate(42, (i) => 'c$i'));
    expect(first.shown.length, 5);
    expect(first.more, 37);
    expect(aiFirstItems(['a', 'b']).more, 0);
  });

  test('a timestamp with no offset is read as UTC', () {
    expect(adminAiUtc('2026-11-21T10:00:00')!.isUtc, isTrue);
    expect(adminAiUtc('2026-11-21T10:00:00Z'), DateTime.utc(2026, 11, 21, 10));
    expect(adminAiUtc('2026-11-21T12:00:00+02:00'), DateTime.utc(2026, 11, 21, 10));
    expect(adminAiUtc(null), isNull);
    expect(adminAiDayValue('2026-11-12T00:00:00')!.isUtc, isFalse);
  });

  test('only https image links open', () {
    expect(isSafeAdminAiLink('https://xd.blob.core.windows.net/a.jpg'), isTrue);
    expect(isSafeAdminAiLink('javascript:alert(1)'), isFalse);
    expect(isSafeAdminAiLink('http://x/a.jpg'), isFalse);
    expect(isSafeAdminAiLink(null), isFalse);
  });
}
