// FS-1026 Receipt AI - scan review and profile editor rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_review_utils.dart';

const _expense = AdminAiScanValues(
  merchant: 'Car Wash Center',
  date: '2026-11-12',
  amount: 80,
  currency: 'ILS',
  receiptNumber: '83875',
);

AdminAiScanReview _review({AdminAiScanValues? mistral, AdminAiScanValues? gpt}) => AdminAiScanReview(
  expenseId: 'e1',
  companyId: 'c1',
  companyName: 'Harbor',
  isClosed: false,
  isForeign: false,
  expense: _expense,
  modelResults: [
    if (mistral != null)
      AdminAiModelResult(step: 'ai-scan', model: 'mistral-document-ai-2512', durationMs: 1, values: mistral),
    if (gpt != null) AdminAiModelResult(step: 'ai-escalation', model: 'gpt-5-mini', durationMs: 1, values: gpt),
  ],
);

void main() {
  group('review form', () {
    test('starts equal to the expense: Verified allowed, Save not', () {
      final form = AdminAiReviewForm(_expense);
      expect(form.changed, isEmpty);
      expect(form.canVerify, isTrue);
      expect(form.canSave(isClosed: false), isFalse);
      expect(form.values[AdminAiField.amount], '80.00');
    });

    test('a changed merchant enables Save and disables Verified', () {
      final form = AdminAiReviewForm(_expense)..values[AdminAiField.merchant] = 'Car Wash Centre';
      expect(form.changed, [AdminAiField.merchant]);
      expect(form.canVerify, isFalse);
      expect(form.canSave(isClosed: false), isTrue);
      expect(form.canSave(isClosed: true), isTrue);
    });

    test('same number or case is not a change', () {
      final form = AdminAiReviewForm(_expense)
        ..values[AdminAiField.amount] = '80'
        ..values[AdminAiField.currency] = 'ils'
        ..values[AdminAiField.merchant] = ' Car Wash Center ';
      expect(form.changed, isEmpty);
    });

    test('a closed expense cannot save a money change', () {
      final form = AdminAiReviewForm(_expense)..values[AdminAiField.amount] = '81';
      expect(form.moneyChanged, isTrue);
      expect(form.canSave(isClosed: false), isTrue);
      expect(form.canSave(isClosed: true), isFalse);
    });

    test('the correction carries every field, trimmed, currency upper-cased', () {
      final c =
          (AdminAiReviewForm(_expense)
                ..values[AdminAiField.currency] = 'usd'
                ..values[AdminAiField.receiptNumber] = '  ')
              .toCorrection();
      expect(c.toJson(), {
        'merchant': 'Car Wash Center',
        'date': '2026-11-12',
        'amount': 80.0,
        'currency': 'USD',
        'receiptNumber': null,
      });
    });
  });

  test('models disagree only when both read the field differently', () {
    final r = _review(
      mistral: const AdminAiScanValues(merchant: 'Car Wash Center', amount: 80),
      gpt: const AdminAiScanValues(merchant: 'Car Wash Centre', amount: 80.0, date: '2026-11-12'),
    );
    expect(aiModelsDisagree(r, AdminAiField.merchant), isTrue);
    expect(aiModelsDisagree(r, AdminAiField.amount), isFalse);
    expect(aiModelsDisagree(r, AdminAiField.date), isFalse); // Mistral read nothing
    expect(aiModelsDisagree(_review(mistral: _expense), AdminAiField.merchant), isFalse); // GPT not called
  });

  group('walking the scan list', () {
    const ids = ['a', 'b', 'c', 'd'];

    test('next unreviewed skips reviewed ones and wraps', () {
      expect(nextUnreviewedId(ids, 'a', {}), 'b');
      expect(nextUnreviewedId(ids, 'a', {'b', 'c'}), 'd');
      expect(nextUnreviewedId(ids, 'd', {'b'}), 'a');
      expect(nextUnreviewedId(ids, 'b', {'a', 'c', 'd'}), isNull);
      expect(nextUnreviewedId(const [], 'a', {}), isNull);
    });

    test('previous is the one before, none at the start', () {
      expect(previousId(ids, 'c'), 'b');
      expect(previousId(ids, 'a'), isNull);
      expect(previousId(ids, 'x'), isNull);
    });
  });

  group('profile editor', () {
    test('dirty once any text differs from what was loaded', () {
      final edit = AdminAiDraftEdit(system: 's', user: 'u', fields: {'date': 'd'});
      expect(edit.isDirty, isFalse);
      edit.fields['date'] = 'd2';
      expect(edit.isDirty, isTrue);
      edit.fields['date'] = 'd';
      expect(edit.isDirty, isFalse);
      edit.user = 'u2';
      expect(edit.isDirty, isTrue);
    });

    test('fields changed from the published version', () {
      expect(AdminAiDraftEdit.fieldsChangedFrom({'date': 'x', 'amount': 'a'}, {'date': 'y', 'amount': 'a'}), {'date'});
      expect(AdminAiDraftEdit.fieldsChangedFrom({'date': 'x'}, null), isEmpty);
    });
  });
}
