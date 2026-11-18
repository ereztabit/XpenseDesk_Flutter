import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/sheet_nav.dart';
import 'package:xpensedesk_flutter/models/sheet_nav_dev_state.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';
import 'package:xpensedesk_flutter/utils/sheet_nav_utils.dart';

void main() {
  const seed = SheetNavDevState.seed;

  group('buildSheetNavSections - who sees the bar', () {
    test('employee with Monthly only sees no bar', () {
      expect(
        buildSheetNavSections(const SheetNavInput(isManager: false)),
        isNull,
      );
    });

    test('manager with Monthly only gets one type with Team and Mine', () {
      final s = buildSheetNavSections(
        const SheetNavInput(isManager: true, teamWaiting: 3, myReturned: 1),
      )!;
      expect(s, hasLength(1));
      expect(s.single.type, SheetNavType.monthly);
      expect(s.single.pages.map((p) => p.kind), [
        SheetNavPageKind.team,
        SheetNavPageKind.mine,
      ]);
      expect(s.single.pages.first.count, 3);
      expect(s.single.pages.last.count, 1);
    });

    test('nothing on hides the bar', () {
      expect(
        buildSheetNavSections(
          const SheetNavInput(isManager: true, monthlyOn: false),
        ),
        isNull,
      );
    });

    test(
      'Budgets not built is coming soon for a manager, hidden for an employee',
      () {
        final manager = buildSheetNavSections(
          const SheetNavInput(isManager: true, budgetsOn: true),
        )!;
        expect(manager.map((s) => s.type), [
          SheetNavType.monthly,
          SheetNavType.budgets,
        ]);
        expect(manager.last.isComingSoon, isTrue);

        expect(
          buildSheetNavSections(
            const SheetNavInput(isManager: false, budgetsOn: true),
          ),
          isNull,
        );
      },
    );

    test('Travel is coming soon for everyone', () {
      final s = buildSheetNavSections(
        const SheetNavInput(isManager: false, travelOn: true),
      )!;
      expect(s.map((x) => x.type), [SheetNavType.monthly, SheetNavType.travel]);
      expect(s.last.isComingSoon, isTrue);
    });

    test('Budgets built: manager gets All budgets then my budgets', () {
      final s = buildSheetNavSections(
        SheetNavInput(
          isManager: true,
          budgetsOn: true,
          budgetsBuilt: true,
          myBudgets: seed.take(2).toList(),
          budgetsBelowZero: 2,
        ),
      )!;
      final budgets = s.firstWhere((x) => x.type == SheetNavType.budgets);
      expect(budgets.pages.map((p) => p.kind), [
        SheetNavPageKind.allBudgets,
        SheetNavPageKind.budget,
        SheetNavPageKind.budget,
      ]);
      expect(budgets.pages.first.count, 2);
      expect(budgets.pages.first.alert, isTrue);
      expect(budgets.pages[2].route, AppRoutes.budgetPath('b2'));
      expect(budgets.pages[2].balance, -80);
    });

    test('FS-1012 S3: budgets awaiting approval badge Budgets for a manager', () {
      SheetNavPage budgetsPage(int toReview, int belowZero) => buildSheetNavSections(
            SheetNavInput(
              isManager: true,
              budgetsOn: true,
              budgetsBuilt: true,
              budgetsToReview: toReview,
              budgetsBelowZero: belowZero,
            ),
          )!.firstWhere((x) => x.type == SheetNavType.budgets).firstPage!;
      expect(budgetsPage(1, 0).count, 1, reason: 'one budget to approve');
      expect(budgetsPage(1, 0).alert, isFalse, reason: 'waiting, not in trouble');
      expect(budgetsPage(3, 1).count, 3);
      expect(budgetsPage(3, 1).alert, isTrue, reason: 'one is over budget or overdue');
      expect(budgetsPage(0, 0).count, 0, reason: 'nothing to do hides the badge');
    });

    test('FS-1012 S3: a returned budget badges the holder\'s Budgets', () {
      final s = buildSheetNavSections(
        const SheetNavInput(
          isManager: false,
          budgetsOn: true,
          budgetsBuilt: true,
          myBudgets: [
            SheetNavMockBudget('a', 'Open one', 100),
            SheetNavMockBudget('b', 'Returned one', 50, returned: true),
          ],
        ),
      )!;
      final budgets = s.firstWhere((x) => x.type == SheetNavType.budgets);
      expect(budgets.pages.map((p) => p.count), [0, 1]);
      expect(budgets.badgeCount, 1, reason: 'the type shows the returned count');
    });

    test('Budgets built: employee without a budget has no Budgets type', () {
      expect(
        buildSheetNavSections(
          const SheetNavInput(
            isManager: false,
            budgetsOn: true,
            budgetsBuilt: true,
          ),
        ),
        isNull,
      );
    });

    test('a single type with one budget page and no Monthly hides the bar', () {
      expect(
        buildSheetNavSections(
          SheetNavInput(
            isManager: false,
            monthlyOn: false,
            budgetsOn: true,
            budgetsBuilt: true,
            myBudgets: seed.take(1).toList(),
          ),
        ),
        isNull,
      );
    });
  });

  group('helpers', () {
    final sections = buildSheetNavSections(
      SheetNavInput(
        isManager: true,
        budgetsOn: true,
        budgetsBuilt: true,
        myBudgets: seed,
      ),
    )!;

    test('sheetNavSectionFor finds the type of a route', () {
      expect(
        sheetNavSectionFor(sections, AppRoutes.employeeDashboard)?.type,
        SheetNavType.monthly,
      );
      expect(
        sheetNavSectionFor(sections, AppRoutes.budgetPath('b3'))?.type,
        SheetNavType.budgets,
      );
      expect(sheetNavSectionFor(sections, AppRoutes.managerUsers), isNull);
    });

    test('sheetNavPageFor finds a page or null', () {
      expect(
        sheetNavPageFor(sections, AppRoutes.budgetPath('b1'))?.label,
        seed.first.name,
      );
      expect(sheetNavPageFor(null, AppRoutes.budgets), isNull);
    });

    test('sheetNavBelowZero counts negative balances', () {
      expect(sheetNavBelowZero(seed), 2);
    });

    test('sheetNavResolve applies the override', () {
      expect(sheetNavResolve(false, SheetNavModuleOverride.server), isFalse);
      expect(sheetNavResolve(false, SheetNavModuleOverride.on), isTrue);
      expect(sheetNavResolve(true, SheetNavModuleOverride.off), isFalse);
    });

    test('AppRoutes.parseBudgetPath', () {
      expect(AppRoutes.parseBudgetPath('/budgets/a1b2c3d4-0000-4000-8000-123456789abc'), 'a1b2c3d4-0000-4000-8000-123456789abc');
      // FS-1013: a non-GUID segment is not a budget page.
      expect(AppRoutes.parseBudgetPath('/budgets/b4'), isNull);
      expect(AppRoutes.parseBudgetPath('/budgets/..%2Fadmin'), isNull);
      expect(AppRoutes.parseBudgetPath('/budgets'), isNull);
      expect(AppRoutes.parseBudgetPath('/dashboard'), isNull);
    });
  });
}
