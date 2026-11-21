// FS-1026 manual-QA fixes: model columns by name, singular counts, LTR labels.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_utils.dart';

AdminAiScanReview _review(List<AdminAiModelResult> results) => AdminAiScanReview(
  expenseId: 'e',
  companyId: 'c',
  companyName: 'C',
  isClosed: false,
  isForeign: false,
  expense: const AdminAiScanValues(),
  modelResults: results,
);

void main() {
  test('a GPT-only scan (Mistral throttled) lands in GPT, Mistral not called', () {
    final r = _review(const [
      AdminAiModelResult(step: 'ai-escalation', model: 'gpt-5-mini', durationMs: 9, reason: 'first-model-throttled'),
    ]);
    expect(r.gpt?.model, 'gpt-5-mini');
    expect(r.mistral, isNull);
  });

  test('Mistral then GPT: each in its own column', () {
    final r = _review(const [
      AdminAiModelResult(step: 'ai-scan', model: 'mistral-document-ai-2512', durationMs: 2),
      AdminAiModelResult(step: 'ai-escalation', model: 'gpt-5-mini', durationMs: 9),
    ]);
    expect(r.mistral?.model, 'mistral-document-ai-2512');
    expect(r.gpt?.model, 'gpt-5-mini');
  });

  test('any other reader (the dev qa-mock) counts as Mistral', () {
    final r = _review(const [AdminAiModelResult(step: 'ai-scan', model: 'qa-mock', durationMs: 0)]);
    expect(r.mistral?.model, 'qa-mock');
    expect(r.gpt, isNull);
  });

  test('singular for one, plural otherwise', () {
    expect(adminAiCount(1, 'company', 'companies'), '1 company');
    expect(adminAiCount(0, 'company', 'companies'), '0 companies');
    expect(adminAiCount(2, 'profile', 'profiles'), '2 profiles');
  });

  test('profile labels are a left-to-right isolate', () {
    expect(adminAiLtr('#1 Standard · v1'), '\u2066#1 Standard · v1\u2069');
  });
}
