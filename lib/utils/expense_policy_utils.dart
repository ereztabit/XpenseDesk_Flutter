/// How a date breaks the expense date window.
enum DatePolicyViolation { tooOld, inFuture }

/// Expense policy checks made on the client (FS-1007 S2). For now only the
/// expense date window, shown on an Action Required expense; a full
/// policy-violation mechanism comes later. The server's save still enforces
/// the rule either way.
class ExpensePolicy {
  ExpensePolicy._();

  /// Longest expense note the user can type; the counter shows under the input.
  static const int noteMaxLength = 300;

  /// The limit on edit: a longer note saved before (e.g. a WhatsApp upload)
  /// keeps its length - it can shrink, never be cut on the first keystroke.
  static int noteLimitFor(String stored) =>
      stored.length > noteMaxLength ? stored.length : noteMaxLength;

  /// Why [date] falls outside the window — more than 12 months before
  /// [today] (defaults to now), or after it — or null when it is inside.
  /// The server's `ExpenseService.IsExpenseDateInRange`, on dates only.
  static DatePolicyViolation? dateViolation(DateTime date, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    if (day.isAfter(DateTime(now.year, now.month, now.day))) {
      return DatePolicyViolation.inFuture;
    }
    if (day.isBefore(DateTime(now.year - 1, now.month, now.day))) {
      return DatePolicyViolation.tooOld;
    }
    return null;
  }
}
