import '../models/sheet_nav.dart';
import '../models/sheet_nav_dev_state.dart';
import 'app_navigator.dart';

/// Inputs of the sheet-type tree, already resolved from role, company modules,
/// counts and the dev preview. Pure data so the rules are unit-testable.
class SheetNavInput {
  final bool isManager;
  final bool monthlyOn;
  final bool budgetsOn;
  final bool travelOn;

  /// Budgets is built (today: dev preview only). False = "coming soon".
  final bool budgetsBuilt;
  final List<SheetNavMockBudget> myBudgets;
  final int teamWaiting;
  final int myReturned;
  final int budgetsBelowZero;

  /// FS-1012 S3: budgets a manager has to act on - awaiting approval, or over
  /// budget / overdue - each once. The "All budgets" (and so the Budgets
  /// type) badge; red only while [budgetsBelowZero] > 0.
  final int budgetsToReview;

  const SheetNavInput({
    required this.isManager,
    this.monthlyOn = true,
    this.budgetsOn = false,
    this.travelOn = false,
    this.budgetsBuilt = false,
    this.myBudgets = const [],
    this.teamWaiting = 0,
    this.myReturned = 0,
    this.budgetsBelowZero = 0,
    this.budgetsToReview = 0,
  });
}

/// Builds the visible types for the user, or null when the bar must not show
/// (spec section 3: no type, or one type with at most one page).
List<SheetNavSection>? buildSheetNavSections(SheetNavInput i) {
  final sections = <SheetNavSection>[];

  if (i.monthlyOn) {
    sections.add(
      SheetNavSection(
        type: SheetNavType.monthly,
        pages: [
          if (i.isManager)
            SheetNavPage(
              kind: SheetNavPageKind.team,
              route: AppRoutes.managerDashboard,
              count: i.teamWaiting,
            ),
          SheetNavPage(
            kind: SheetNavPageKind.mine,
            route: AppRoutes.employeeDashboard,
            count: i.myReturned,
          ),
        ],
      ),
    );
  }

  if (i.budgetsOn) {
    if (i.budgetsBuilt) {
      final pages = [
        if (i.isManager)
          SheetNavPage(
            kind: SheetNavPageKind.allBudgets,
            route: AppRoutes.budgets,
            count: i.budgetsToReview > i.budgetsBelowZero ? i.budgetsToReview : i.budgetsBelowZero,
            alert: i.budgetsBelowZero > 0,
          ),
        for (final b in i.myBudgets)
          SheetNavPage(
            kind: SheetNavPageKind.budget,
            route: AppRoutes.budgetPath(b.id),
            label: b.name,
            balance: b.balance,
            count: b.returned ? 1 : 0,
          ),
      ];
      // An employee without a budget has nothing to see in Budgets.
      if (pages.isNotEmpty) {
        sections.add(SheetNavSection(type: SheetNavType.budgets, pages: pages));
      }
    } else if (i.isManager) {
      sections.add(const SheetNavSection(type: SheetNavType.budgets));
    }
  }

  if (i.travelOn) {
    sections.add(const SheetNavSection(type: SheetNavType.travel));
  }

  if (sections.isEmpty) return null;
  if (sections.length == 1 && sections.single.pages.length <= 1) return null;
  return sections;
}

/// The section holding [route], or null when the route is outside the tree.
SheetNavSection? sheetNavSectionFor(
  List<SheetNavSection> sections,
  String route,
) {
  for (final s in sections) {
    if (s.pages.any((p) => p.route == route)) return s;
  }
  return null;
}

/// The page at [route] in the visible tree, or null.
SheetNavPage? sheetNavPageFor(List<SheetNavSection>? sections, String route) {
  for (final s in sections ?? const <SheetNavSection>[]) {
    for (final p in s.pages) {
      if (p.route == route) return p;
    }
  }
  return null;
}

/// The tree route the current page belongs to: the route without its query;
/// any Budgets page that is not one of the user's own budgets (the list,
/// someone else's budget) keeps "All budgets" active (hand-off section 2.6).
String sheetNavActiveRoute(List<SheetNavSection> sections, String route) {
  final path = Uri.parse(route).path;
  if (sheetNavPageFor(sections, path) != null) return path;
  if (path == AppRoutes.budgets || path.startsWith('${AppRoutes.budgets}/')) {
    return AppRoutes.budgets;
  }
  return path;
}

/// Number of budgets below zero, for the All budgets badge.
int sheetNavBelowZero(Iterable<SheetNavMockBudget> budgets) =>
    budgets.where((b) => b.balance < 0).length;

/// Applies a dev override to the server's answer.
bool sheetNavResolve(bool server, SheetNavModuleOverride override) =>
    switch (override) {
      SheetNavModuleOverride.server => server,
      SheetNavModuleOverride.on => true,
      SheetNavModuleOverride.off => false,
    };
