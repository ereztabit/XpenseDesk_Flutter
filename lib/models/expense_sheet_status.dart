/// Server-side expense sheet status. Mirrors `ExpenseSheetStatusId` on the API
/// (see docs/in-progress/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md §0.2).
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

/// UI-only mode derived from [ExpenseSheetStatus]. Drives the picker styling,
/// the "+ New expense" button gating, the filter tabs, and the declined banner
/// on the employee dashboard.
///
/// Mapping is 1:1 with the server status (`approved=3` never reaches this
/// screen — finalised sheets live in history).
enum SheetMode {
  draft,
  submitted,
  declined;

  static SheetMode? fromStatus(ExpenseSheetStatus? status) {
    if (status == null) return null;
    switch (status) {
      case ExpenseSheetStatus.draft:
        return SheetMode.draft;
      case ExpenseSheetStatus.waitingForApproval:
        return SheetMode.submitted;
      case ExpenseSheetStatus.declined:
        return SheetMode.declined;
      case ExpenseSheetStatus.approved:
        return null;
    }
  }

  static SheetMode? fromStatusId(int? id) =>
      fromStatus(ExpenseSheetStatus.fromId(id));
}
