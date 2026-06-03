import 'screen_imports.dart';
import '../models/expense_sheet_list_item.dart';
import '../providers/employee_dashboard_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../utils/sheet_utils.dart';
import '../widgets/employee_dashboard/employee_dashboard_body.dart';
import '../widgets/employee_dashboard/page_header_row.dart';
import '../widgets/employee_dashboard/sheet_expense_empty_state.dart';

/// Sheet-centric employee dashboard.
///
/// Layout: page header (title + view-mode toggle + New Expense) above a
/// scrollable body containing the returned-sheets global alert, the sheet
/// picker, the declined banner (when applicable), the per-expense filter
/// tabs (when applicable), and the expense list.
///
/// The orchestrator owns scaffold + default-selection bootstrapping; every
/// visual section is its own widget under `lib/widgets/employee_dashboard/`.
class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(mySheetsProvider);
    });
  }

  /// Schedules a default selection when the current `selectedId` is null or
  /// no longer in the visible list. Selection rules live in [SheetSelection].
  void _ensureSelection(
    List<ExpenseSheetListItem> visible,
    String? selectedId,
  ) {
    final selectionExists = selectedId != null &&
        visible.any((s) => s.expenseSheetId == selectedId);
    if (selectionExists) return;
    final defaultSheet = SheetSelection.defaultSelection(visible);
    if (defaultSheet == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(selectedSheetIdProvider.notifier)
          .set(defaultSheet.expenseSheetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheetsAsync = ref.watch(mySheetsProvider);
    final selectedId = ref.watch(selectedSheetIdProvider);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: RefreshableScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: sheetsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.failedToLoadExpenses,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.destructive),
                      ),
                    ),
                    data: (sheets) =>
                        _buildContent(context, l10n, sheets, selectedId),
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

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<ExpenseSheetListItem> allSheets,
    String? selectedId,
  ) {
    final visible = SheetSelection.nonFinalised(allSheets);
    _ensureSelection(visible, selectedId);

    if (visible.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeaderRow(
            newExpenseEnabled: true,
            onNewExpense: () => Navigator.of(context)
                .pushNamed('/employee/new-expense')
                .then((_) => ref.invalidate(mySheetsProvider)),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Center(
                child: SheetExpenseEmptyState(
                  title: l10n.employeeEmptyStateTitle,
                  description: l10n.employeeEmptyStateDesc,
                  actionLabel: l10n.newExpense,
                  onAction: () => Navigator.of(context)
                      .pushNamed('/employee/new-expense')
                      .then((_) => ref.invalidate(mySheetsProvider)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final selectedSheet = selectedId != null &&
            visible.any((s) => s.expenseSheetId == selectedId)
        ? visible.firstWhere((s) => s.expenseSheetId == selectedId)
        : SheetSelection.defaultSelection(visible)!;

    final isCurrentDraft =
        SheetSelection.isCurrentCycleDraft(selectedSheet, allSheets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeaderRow(
          newExpenseEnabled: isCurrentDraft,
          onNewExpense: () => Navigator.of(context)
              .pushNamed('/employee/new-expense')
              .then((_) {
            ref.invalidate(mySheetsProvider);
            ref.invalidate(sheetDetailProvider(selectedSheet.expenseSheetId));
          }),
        ),
        const SizedBox(height: 24),
        EmployeeDashboardBody(
          visibleSheets: visible,
          selectedSheet: selectedSheet,
        ),
      ],
    );
  }
}
