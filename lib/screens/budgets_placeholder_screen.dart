import 'screen_imports.dart';
import '../models/sheet_nav.dart';
import '../providers/sheet_nav_provider.dart';
import '../utils/app_navigator.dart';
import '../utils/format_utils.dart';
import '../utils/sheet_nav_display_utils.dart';
import '../utils/sheet_nav_utils.dart';
import '../widgets/route_redirector.dart';
import '../widgets/sheet_nav/sheet_nav_dev_button.dart';
import '../widgets/sheet_nav/sheet_nav_placeholder_card.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';

/// Placeholder for the Budgets pages (FS-1012) until PC-1 designs them:
/// All budgets (`/budgets`) and one budget (`/budgets/<id>`).
///
/// Reachable only while the page is in the user's sheet-type tree (today: the
/// dev Budgets preview); otherwise it bounces to the user's home dashboard.
class BudgetsPlaceholderScreen extends ConsumerStatefulWidget {
  const BudgetsPlaceholderScreen({super.key, this.budgetId});

  /// Null = All budgets.
  final String? budgetId;

  @override
  ConsumerState<BudgetsPlaceholderScreen> createState() =>
      _BudgetsPlaceholderScreenState();
}

class _BudgetsPlaceholderScreenState
    extends ConsumerState<BudgetsPlaceholderScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userInfoProvider);
    final route = widget.budgetId == null
        ? AppRoutes.budgets
        : AppRoutes.budgetPath(widget.budgetId!);
    final page = sheetNavPageFor(ref.watch(sheetNavProvider), route);

    if (page == null) {
      return RouteRedirector(
        route: user?.isManager == true
            ? AppRoutes.managerDashboard
            : AppRoutes.employeeDashboard,
      );
    }

    final locale = ref.watch(companyLocaleProvider);
    final currency = user?.currencyCode ?? 'ILS';
    final isBudget = page.kind == SheetNavPageKind.budget;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        floatingActionButton: const SheetNavDevButton(),
        body: Column(
          children: [
            const AppHeader(),
            const SheetTypeBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.caption(l10n),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SheetNavPlaceholderCard(
                        title: page.caption(l10n),
                        body: isBudget
                            ? l10n.sheetNavBudgetPlaceholder
                            : l10n.sheetNavAllBudgetsPlaceholder,
                        amount: page.balance?.toCurrency(locale, currency),
                        amountNegative: page.isBelowZero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
