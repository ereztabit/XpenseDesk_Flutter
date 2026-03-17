import '../models/expense_cycle.dart';

extension CycleListUtils on List<ExpenseCycle> {
  /// Returns the current cycle using this resolution order:
  ///   1. The open cycle (`cycleStatus == 'Open'`) with a non-empty ID.
  ///   2. The first cycle with a non-empty ID (most recent, as returned by the API).
  ///   3. null if the list is empty or all IDs are empty.
  ExpenseCycle? get currentCycle {
    final open = where((c) => c.isOpen && c.expenseCycleId.isNotEmpty);
    if (open.isNotEmpty) return open.first;
    final any = where((c) => c.expenseCycleId.isNotEmpty);
    return any.isNotEmpty ? any.first : null;
  }

  /// Finds a cycle by ID, falling back to [currentCycle] if not found or ID is empty.
  ExpenseCycle? cycleById(String? id) {
    if (id != null && id.isNotEmpty) {
      final match = where((c) => c.expenseCycleId == id);
      if (match.isNotEmpty) return match.first;
    }
    return currentCycle;
  }
}
