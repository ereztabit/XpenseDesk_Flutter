/// Server-side expense sheet status. Mirrors `ExpenseSheetStatusId` on the API
/// (see docs/completed/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md §0.2).
enum ExpenseSheetStatus {
  draft(1),
  waitingForApproval(2),
  approved(3),
  declined(4);

  const ExpenseSheetStatus(this.id);

  final int id;

  static ExpenseSheetStatus? fromId(int? id) {
    if (id == null) return null;
    for (final status in ExpenseSheetStatus.values) {
      if (status.id == id) return status;
    }
    return null;
  }
}
