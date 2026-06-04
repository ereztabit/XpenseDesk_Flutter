import '../models/dashboard_ui_state.dart';
import '../models/expense_sheet_list_item.dart';
import '../models/expense_sheet_status.dart';
import '../models/expense_summary.dart';

/// Sheet domain helpers — pure functions on sheet/expense data with no widget
/// dependencies. Grouped by concern; one file so manager dashboard (story 02)
/// and Sheet Review (story 03) reuse the same primitives.
///
/// Layout mirrors `lib/utils/format_utils.dart`: one file, multiple classes
/// organised by theme.

// ─── Selection ──────────────────────────────────────────────────────────────

/// Helpers that decide "which sheet is the current cycle's Draft", "what
/// default selection should the picker open with", "what order does the
/// dropdown render", etc.
class SheetSelection {
  SheetSelection._();

  /// Strip finalised (Approved) sheets — those live in history and never
  /// appear on the employee dashboard.
  static List<ExpenseSheetListItem> nonFinalised(
    List<ExpenseSheetListItem> all,
  ) {
    return all
        .where((s) =>
            s.expenseSheetStatusId != ExpenseSheetStatus.approved.id)
        .toList(growable: false);
  }

  /// Default picker selection — the current-cycle Draft if it exists,
  /// otherwise the newest non-finalised sheet.
  static ExpenseSheetListItem? defaultSelection(
    List<ExpenseSheetListItem> visible,
  ) {
    if (visible.isEmpty) return null;
    final drafts = visible
        .where((s) =>
            s.expenseSheetStatusId == ExpenseSheetStatus.draft.id)
        .toList();
    if (drafts.isNotEmpty) {
      drafts.sort((a, b) => b.cycleLabel.compareTo(a.cycleLabel));
      return drafts.first;
    }
    final sorted = [...visible];
    sorted.sort((a, b) => b.cycleLabel.compareTo(a.cycleLabel));
    return sorted.first;
  }

  /// True when `sheet` is the Draft for the highest cycle label across `all`.
  /// Drives the "+ New expense" button gating — only the current-cycle Draft
  /// can accept new expenses.
  static bool isCurrentCycleDraft(
    ExpenseSheetListItem sheet,
    List<ExpenseSheetListItem> all,
  ) {
    if (sheet.expenseSheetStatusId != ExpenseSheetStatus.draft.id) {
      return false;
    }
    if (all.isEmpty) return false;
    final maxCycle = all
        .map((s) => s.cycleLabel)
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return sheet.cycleLabel == maxCycle;
  }

  /// Picker dropdown order: current-cycle non-reopened Draft first, then
  /// remaining active sheets by cycle label descending.
  static List<ExpenseSheetListItem> pickerOrder(
    List<ExpenseSheetListItem> sheets,
  ) {
    final list = [...sheets];
    list.sort((a, b) {
      final aIsDraft =
          a.expenseSheetStatusId == ExpenseSheetStatus.draft.id ? 0 : 1;
      final bIsDraft =
          b.expenseSheetStatusId == ExpenseSheetStatus.draft.id ? 0 : 1;
      if (aIsDraft != bIsDraft) return aIsDraft - bIsDraft;
      return b.cycleLabel.compareTo(a.cycleLabel);
    });
    return list;
  }

  /// Stable dismissal key for the returned-sheets global alert — sorted IDs
  /// joined by `|`. The alert reappears when the set of returned sheets
  /// changes (key mismatch).
  static String dismissalKey(List<ExpenseSheetListItem> returnedSheets) {
    final ids =
        returnedSheets.map((s) => s.expenseSheetId).toList(growable: false)
          ..sort();
    return ids.join('|');
  }
}

// ─── Expense bucket math ────────────────────────────────────────────────────

/// Filter / count / total helpers used by the declined-sheet filter tabs.
/// Pure data math — no widget knowledge.
class SheetExpenseBuckets {
  SheetExpenseBuckets._();

  /// Server `expenseStatusId` for a given UI filter tab.
  static int statusIdForTab(FilterTab tab) => switch (tab) {
        FilterTab.rejected => 3,
        FilterTab.pending => 1,
        FilterTab.approved => 2,
      };

  /// Subset of [all] matching [tab].
  static List<ExpenseSummary> filterByTab(
    List<ExpenseSummary> all,
    FilterTab tab,
  ) {
    final targetId = statusIdForTab(tab);
    return all
        .where((e) => e.expenseStatusId == targetId)
        .toList(growable: false);
  }

  /// Map of `FilterTab → expense count`, computed in one pass.
  static Map<FilterTab, int> countsPerTab(List<ExpenseSummary> all) {
    var rejected = 0, pending = 0, approved = 0;
    for (final e in all) {
      switch (e.expenseStatusId) {
        case 1:
          pending++;
        case 2:
          approved++;
        case 3:
          rejected++;
      }
    }
    return {
      FilterTab.rejected: rejected,
      FilterTab.pending: pending,
      FilterTab.approved: approved,
    };
  }
}

// ─── Permissions ────────────────────────────────────────────────────────────

/// Edit / delete authority. Mirrors the server matrix in
/// `docs/in-progress/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md §0.7`.
///
/// UI should mirror these checks so we don't paint buttons that will 409 / 403.
/// Server enforces the same rules — these are a pre-emptive client check.
class SheetPermissions {
  SheetPermissions._();

  /// Can the current user edit this expense?
  ///
  /// Manager: always true (escape hatch, no status change on server).
  /// Employee:
  ///   - Draft sheet → only Pending expenses (only ones that exist on Draft).
  ///   - WaitingForApproval sheet → no (read-only).
  ///   - Approved sheet → no (finalised; this never reaches the employee dashboard anyway).
  ///   - Declined sheet → Pending or Declined; **not** Approved (server 409
  ///     `ExpenseEditApprovedExpenseOnDeclinedSheet`). Editing a Declined
  ///     expense auto-resets it to Pending and re-evaluates the sheet.
  static bool canEditExpense({
    required int sheetStatusId,
    required int expenseStatusId,
    required bool isManager,
  }) {
    if (isManager) return true;
    switch (sheetStatusId) {
      case 1: // Draft
        return expenseStatusId == 1; // Pending
      case 4: // Declined
        return expenseStatusId == 1 || expenseStatusId == 3; // Pending or Declined
      default: // WaitingForApproval (2), Approved (3)
        return false;
    }
  }

  /// Can the current user delete this expense?
  ///
  /// Manager: any sheet except Approved (escape hatch — Draft, WaitingForApproval
  /// or Declined are all deletable).
  /// Employee:
  ///   - Draft sheet → Pending only.
  ///   - WaitingForApproval / Approved → no.
  ///   - Declined sheet → Pending or Declined; **not** Approved (server 403).
  static bool canDeleteExpense({
    required int sheetStatusId,
    required int expenseStatusId,
    required bool isManager,
  }) {
    if (isManager) {
      // Escape hatch: delete on any sheet except Approved.
      return sheetStatusId != 3; // 3 = Approved
    }
    switch (sheetStatusId) {
      case 1: // Draft
        return expenseStatusId == 1; // Pending
      case 4: // Declined
        return expenseStatusId == 1 || expenseStatusId == 3;
      default:
        return false;
    }
  }
}
