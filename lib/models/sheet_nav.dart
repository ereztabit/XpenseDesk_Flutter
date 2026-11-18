/// The sheet-type navigation tree (docs/completed/sheet-type-nav-spec.md).
///
/// Level 1 of the bar is a list of [SheetNavSection]s (one per sheet type),
/// level 2 is the [SheetNavPage]s of one section.
enum SheetNavType { monthly, budgets, travel }

/// What a page is, so the bar can pick its icon and caption without strings.
enum SheetNavPageKind { team, mine, allBudgets, budget }

class SheetNavPage {
  final SheetNavPageKind kind;

  /// Route name to navigate to.
  final String route;

  /// Free-text label (budget names). Null for fixed pages, which the widget
  /// localises from [kind].
  final String? label;

  /// Waiting count shown as a badge; 0 hides it.
  final int count;

  /// Badge drawn in the destructive colour (e.g. budgets below zero).
  final bool alert;

  /// Budget balance in the company currency; null for non-budget pages.
  final double? balance;

  const SheetNavPage({
    required this.kind,
    required this.route,
    this.label,
    this.count = 0,
    this.alert = false,
    this.balance,
  });
}

class SheetNavSection {
  final SheetNavType type;

  /// Empty when the type is "coming soon": it shows at level 1, disabled.
  final List<SheetNavPage> pages;

  const SheetNavSection({required this.type, this.pages = const []});

  bool get isComingSoon => pages.isEmpty;

  /// The level-1 badge is the badge of the type's first page.
  SheetNavPage? get firstPage => pages.isEmpty ? null : pages.first;

  /// FS-1012 S3: the level-1 badge. The first page's, except an employee's
  /// Budgets (no "All budgets" page): the count of their returned budgets.
  int get badgeCount => type == SheetNavType.budgets &&
          firstPage?.kind != SheetNavPageKind.allBudgets
      ? pages.fold(0, (sum, p) => sum + p.count)
      : firstPage?.count ?? 0;
}
