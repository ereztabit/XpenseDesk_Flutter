// FS-1007 S2: a bulk-upload receipt dated outside the expense window (more
// than 12 months old, or in the future) is kept as Action Required with its
// date, and the edit screen flags the policy on the client. The boundaries
// must match the server (ExpenseService.IsExpenseDateInRange).
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/expense_policy_utils.dart';

void main() {
  final today = DateTime(2026, 9, 29, 15, 30);
  DatePolicyViolation? check(DateTime d) =>
      ExpensePolicy.dateViolation(d, today: today);

  test('exactly 12 months ago and today are both inside the window', () {
    expect(check(DateTime(2025, 9, 29)), isNull);
    expect(check(DateTime(2026, 9, 29, 23, 59)), isNull);
    expect(check(DateTime(2026, 9, 1)), isNull);
  });

  test('a day before 12 months ago is too old', () {
    expect(check(DateTime(2025, 9, 28)), DatePolicyViolation.tooOld);
    expect(check(DateTime(2024, 9, 29)), DatePolicyViolation.tooOld);
  });

  test('tomorrow onwards is in the future', () {
    expect(check(DateTime(2026, 9, 30)), DatePolicyViolation.inFuture);
    expect(check(DateTime(2027, 1, 5)), DatePolicyViolation.inFuture);
  });

  test('the time of day never matters', () {
    expect(
        ExpensePolicy.dateViolation(DateTime(2025, 9, 29, 23, 59),
            today: DateTime(2026, 9, 29)),
        isNull);
  });
}
