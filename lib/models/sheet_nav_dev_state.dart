/// ENV=dev only: lets us preview the sheet-type bar with Budgets as if they
/// were built, and force each module on/off without touching the database.
enum SheetNavModuleOverride { server, on, off }

class SheetNavMockBudget {
  final String id;
  final String name;
  final double balance;

  const SheetNavMockBudget(this.id, this.name, this.balance);
}

class SheetNavDevState {
  /// Treat Budgets as built: All budgets for managers, mock budgets as mine.
  final bool budgetsPreview;

  /// How many of [seed] are assigned to me (0..seed.length).
  final int budgetsAssigned;

  final SheetNavModuleOverride monthly;
  final SheetNavModuleOverride budgets;
  final SheetNavModuleOverride travel;

  const SheetNavDevState({
    this.budgetsPreview = false,
    this.budgetsAssigned = 4,
    this.monthly = SheetNavModuleOverride.server,
    this.budgets = SheetNavModuleOverride.server,
    this.travel = SheetNavModuleOverride.server,
  });

  static const SheetNavDevState production = SheetNavDevState();

  /// Long first name on purpose: budget names are free text.
  static const List<SheetNavMockBudget> seed = [
    SheetNavMockBudget(
      'b1',
      'Office supplies and hospitality - Tel Aviv headquarters',
      420,
    ),
    SheetNavMockBudget('b2', 'Events', -80),
    SheetNavMockBudget('b3', 'Field team', 1250),
    SheetNavMockBudget('b4', 'Warehouse - Haifa', 310),
    SheetNavMockBudget('b5', 'Client visits', -45),
  ];

  List<SheetNavMockBudget> get myBudgets =>
      budgetsPreview ? seed.take(budgetsAssigned).toList() : const [];

  SheetNavDevState copyWith({
    bool? budgetsPreview,
    int? budgetsAssigned,
    SheetNavModuleOverride? monthly,
    SheetNavModuleOverride? budgets,
    SheetNavModuleOverride? travel,
  }) {
    return SheetNavDevState(
      budgetsPreview: budgetsPreview ?? this.budgetsPreview,
      budgetsAssigned: budgetsAssigned ?? this.budgetsAssigned,
      monthly: monthly ?? this.monthly,
      budgets: budgets ?? this.budgets,
      travel: travel ?? this.travel,
    );
  }
}
