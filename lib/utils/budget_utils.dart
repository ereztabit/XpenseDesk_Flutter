import '../models/budget.dart';

export 'budget_edit_utils.dart';

/// Business rules of the Budgets screens (UX hand-off section 5), as pure
/// functions so they are unit-testable and shared by the dashboard, the list,
/// the budget page and the nav.

/// The list sections, in screen order. Values are the sheet status ids.
enum BudgetSection {
  awaiting(2, 'submitted'),
  returned(4, 'returned'),
  open(1, 'draft');

  const BudgetSection(this.statusId, this.focusKey);

  final int statusId;

  /// The `focus` query value of `/budgets/list` (the mock's names).
  final String focusKey;

  static BudgetSection? fromFocus(String? key) {
    for (final s in values) {
      if (s.focusKey == key) return s;
    }
    return null;
  }
}

const int budgetApprovedStatusId = 3;

/// Today as a date only.
DateTime budgetToday([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

bool budgetIsOutstanding(Budget b) => b.statusId != budgetApprovedStatusId;

/// Judged on whole units, as every Budgets amount is shown (-0.40 reads ₪0).
bool budgetIsOverBudget(Budget b) => b.balance.round() < 0;

/// Whole days since the end date while outstanding; 0 when not overdue.
/// Counted on UTC calendar dates: local midnights across a DST change are 23
/// or 25 hours apart and would lose or gain a day.
int budgetOverdueDays(Budget b, DateTime today) {
  final t = DateTime.utc(today.year, today.month, today.day);
  final end = DateTime.utc(b.endDate.year, b.endDate.month, b.endDate.day);
  if (!budgetIsOutstanding(b) || !t.isAfter(end)) return 0;
  return t.difference(end).inDays;
}

bool budgetNeedsAttention(Budget b, DateTime today) =>
    budgetIsOutstanding(b) &&
    (budgetIsOverBudget(b) || budgetOverdueDays(b, today) > 0);

/// Spent / budget as a fraction (can exceed 1).
double budgetUsedFraction(Budget b) =>
    b.budgetAmount <= 0 ? 0 : b.spentAmount / b.budgetAmount;

int budgetUsedPercent(Budget b) => (budgetUsedFraction(b) * 100).round();

/// Spent / budget over several budgets (the dashboard spend card).
double budgetTotalsFraction(Iterable<Budget> budgets) {
  final t = budgetTotals(budgets);
  return t.budget <= 0 ? 0 : t.spent / t.budget;
}

/// Counts for the dashboard attention strip and the nav badge.
class BudgetAttentionCounts {
  final int needAttention;
  final int overBudget;
  final int overdue;

  const BudgetAttentionCounts(this.needAttention, this.overBudget, this.overdue);
}

BudgetAttentionCounts budgetAttentionCounts(Iterable<Budget> budgets, DateTime today) {
  var need = 0, over = 0, late = 0;
  for (final b in budgets.where(budgetIsOutstanding)) {
    if (budgetNeedsAttention(b, today)) need++;
    if (budgetIsOverBudget(b)) over++;
    if (budgetOverdueDays(b, today) > 0) late++;
  }
  return BudgetAttentionCounts(need, over, late);
}

/// FS-1012 S3: outstanding budgets a manager has to act on - awaiting approval,
/// or over budget / overdue - each counted once (the nav badge).
int budgetsToReviewCount(Iterable<Budget> budgets, DateTime today) => budgets
    .where((b) =>
        budgetIsOutstanding(b) &&
        (b.statusId == BudgetSection.awaiting.statusId || budgetNeedsAttention(b, today)))
    .length;

int budgetCountIn(Iterable<Budget> budgets, BudgetSection section) =>
    budgets.where((b) => b.statusId == section.statusId).length;

/// Search on budget name, `#number` (with or without '#') or holder name /
/// email, case-insensitive.
bool budgetMatches(Budget b, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return b.name.toLowerCase().contains(q) ||
      '#${b.number}'.contains(q) ||
      (b.holderName ?? '').toLowerCase().contains(q) ||
      b.holderEmail.toLowerCase().contains(q);
}

/// The list filters: holder, search and the attention toggle.
List<Budget> budgetFilter(
  Iterable<Budget> budgets, {
  String? holderUserId,
  String query = '',
  bool attentionOnly = false,
  required DateTime today,
}) =>
    budgets
        .where((b) => holderUserId == null || b.holderUserId == holderUserId)
        .where((b) => budgetMatches(b, query))
        .where((b) => !attentionOnly || budgetNeedsAttention(b, today))
        .toList();

/// Inside a section: attention first, then end date ascending.
List<Budget> budgetSorted(Iterable<Budget> budgets, DateTime today) {
  final list = budgets.toList();
  list.sort((a, b) {
    final aa = budgetNeedsAttention(a, today) ? 0 : 1;
    final bb = budgetNeedsAttention(b, today) ? 0 : 1;
    if (aa != bb) return aa.compareTo(bb);
    final byEnd = a.endDate.compareTo(b.endDate);
    return byEnd != 0 ? byEnd : a.number.compareTo(b.number);
  });
  return list;
}

/// Totals of the dashboard spend card.
({double spent, double budget, double balance}) budgetTotals(Iterable<Budget> budgets) {
  var spent = 0.0, budget = 0.0;
  for (final b in budgets) {
    spent += b.spentAmount;
    budget += b.budgetAmount;
  }
  return (spent: spent, budget: budget, balance: budget - spent);
}

/// Holders of the listed budgets, alphabetically, for the employee filter.
List<({String userId, String name})> budgetHolders(Iterable<Budget> budgets) {
  final byId = <String, String>{};
  for (final b in budgets) {
    byId[b.holderUserId] = b.holderDisplayName;
  }
  final list = byId.entries.map((e) => (userId: e.key, name: e.value)).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

/// FS-1012 S2a budget page search: merchant name or amount, case-insensitive;
/// an amount matches as typed ("60" finds 60, 60.5, 160).
bool budgetExpenseMatches(String? merchantName, double? amount, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if ((merchantName ?? '').toLowerCase().contains(q)) return true;
  if (amount == null) return false;
  final whole = amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : null;
  return amount.toStringAsFixed(2).contains(q) ||
      amount.toString().contains(q) ||
      (whole?.contains(q) ?? false);
}

/// The signed-in user (by email) holds [b].
bool budgetIsHeldBy(Budget b, String? email) =>
    email != null && b.holderEmail.toLowerCase() == email.toLowerCase();

/// FS-1012 S2a: the holder or any manager adds / edits / deletes a budget's
/// expenses until it is Approved (user decision 2026-11-17; the server checks
/// the same rule).
bool budgetExpensesEditable(Budget b, {required String? email, required bool isManager}) =>
    budgetIsOutstanding(b) && (isManager || budgetIsHeldBy(b, email));

/// The budget page shows its Activity once the trail has more than one entry
/// - a lone "Budget created" adds nothing; a submission or any manager change
/// shows it (user decision 2026-11-18, FS-1013 - was: from the first
/// submission).
bool budgetActivityVisible(int logLength) => logLength > 1;

/// The budget page shows its expense search from this many expenses on -
/// searching three receipts is noise (user decision 2026-11-17: from the 5th).
const int budgetSearchThreshold = 5;

bool budgetShowsSearch(int expenseCount) => expenseCount >= budgetSearchThreshold;

/// The list table's budget name: at most [max] characters, then "…" (the
/// full name is in the cell's tooltip) - user decision 2026-11-17.
String budgetShortName(String name, [int max = 40]) =>
    name.runes.length <= max ? name : '${String.fromCharCodes(name.runes.take(max))}…';

