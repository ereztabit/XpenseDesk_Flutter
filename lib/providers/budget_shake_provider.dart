import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FS-1025 #17: bumped when someone taps a blocked "Submit for approval" -
/// the budget's Needs action card (or the manager's review list) shakes to
/// show what blocks it. One counter per budget id.
final budgetNeedsActionShakeProvider =
    NotifierProvider.autoDispose.family<BudgetShakeNotifier, int, String>(BudgetShakeNotifier.new);

class BudgetShakeNotifier extends Notifier<int> {
  BudgetShakeNotifier(this.budgetId);

  final String budgetId;

  @override
  int build() => 0;

  void shake() => state++;
}
