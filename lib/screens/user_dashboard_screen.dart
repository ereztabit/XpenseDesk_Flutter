import 'screen_imports.dart';
import '../widgets/expenses/expense_status_toggle.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with FormBehaviorMixin {
  bool _isLoading = true;

  /// Currently selected filter: 1=Pending, 2=Approved, 3=Declined
  int _selectedStatusId = 1;

  /// Placeholder counts — will be driven by API data in a future iteration.
  final Map<int, int> _counts = {1: 0, 2: 0, 3: 0};

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await ref.read(userInfoProvider.notifier).loadFromSession();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userInfo = ref.watch(userInfoProvider);
    final l10n = AppLocalizations.of(context)!;

    if (userInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }

    if (userInfo.roleId == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return const SizedBox.shrink();
    }

    if (userInfo.termsConsentDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/employee/onboarding');
      });
      return const SizedBox.shrink();
    }

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ─────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.myExpenses,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/employee/new-expense'),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.newExpense),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Status toggle ──────────────────────────────────
                      ExpenseStatusToggle(
                        selectedStatusId: _selectedStatusId,
                        counts: _counts,
                        onChanged: (id) =>
                            setState(() => _selectedStatusId = id),
                      ),
                      const SizedBox(height: 12),

                      // ── Debug label ────────────────────────────────────
                      Text(
                        'Selected expenseStatusId: $_selectedStatusId',
                        style: Theme.of(context).textTheme.bodyMedium,
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
