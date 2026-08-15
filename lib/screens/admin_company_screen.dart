import 'screen_imports.dart';
import '../utils/app_navigator.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin/admin_company_users_body.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/app_button.dart';
import '../widgets/module_tab_bar.dart';

/// One company's module (`/admin/companies/{companyId}/users`) — admin module
/// #2 (FS-1001).
///
/// A tabbed shell rather than a single people screen, because people are only
/// the first thing platform ops will want to see about a company. Later tabs
/// (billing, cycles, config) drop in as another entry in [_tabs] and another
/// path segment; nothing about the shell or the routing has to change.
///
/// The company id comes from the PATH, so refresh and bookmarking work. The
/// company NAME is resolved from the already-loaded companies list rather than
/// passed in — route arguments are null on a cold load, and the people endpoint
/// deliberately does not repeat the name.
///
/// Deviates from the standard `Expanded -> SingleChildScrollView ->
/// ConstrainedContent` scaffold, as the companies table and the Cycle Expenses
/// report do and for the same reason: the tables have sticky headers and scroll
/// their own rows, so they need a bounded height rather than an unbounded
/// scrolling page.
class AdminCompanyScreen extends ConsumerStatefulWidget {
  const AdminCompanyScreen({
    super.key,
    required this.companyId,
    this.initialTab,
  });

  final String companyId;

  /// Path segment, e.g. `users`. Unknown or absent falls back to the first tab.
  final String? initialTab;

  @override
  ConsumerState<AdminCompanyScreen> createState() => _AdminCompanyScreenState();
}

class _AdminCompanyScreenState extends ConsumerState<AdminCompanyScreen>
    with FormBehaviorMixin, SingleTickerProviderStateMixin {
  /// Tab order is the URL contract — a tab's index is what its path segment
  /// resolves to, so new tabs are appended, never inserted.
  static const List<String> _tabs = [AppRoutes.adminCompanyTabUsers];

  late final TabController _tabController;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();

    final initialIndex = _tabs.indexOf(widget.initialTab ?? '');
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      vsync: this,
    );

    // Deferred past the first frame, and it MUST be: this screen is inflated
    // during AdminAuthGate's build, so initState runs inside the build phase and
    // Riverpod throws "Tried to modify a provider while the widget tree was
    // building" on any write made directly here.
    //
    // The stale-data risk that deferring creates — the keepAlive notifier still
    // holding the previously-opened company — is handled on the DATA instead:
    // the state carries its company id and AdminCompanyUsersQuery renders
    // nothing until it matches. Correctness does not depend on this timing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(adminCompanyUsersProvider.notifier).load(widget.companyId);

      // A fresh company starts with the default view. Left sticky, an agent who
      // ticked "show deactivated" or typed a search once would carry both into
      // every company they open afterwards.
      ref.read(adminShowInactiveUsersProvider.notifier).set(false);
      ref.read(adminCompanyUserSearchProvider.notifier).setQuery('');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// The companies list is already loaded (or loading) behind the admin shell,
  /// so the name costs no extra call. Empty until it arrives, which reads as a
  /// blank title for a moment rather than a wrong one.
  String _companyName() {
    final companies = ref.watch(adminCompaniesProvider).asData?.value;
    if (companies == null) return '';

    for (final company in companies) {
      if (company.companyId == widget.companyId) return company.companyName;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AdminHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ConstrainedContent(
                  maxWidth: AppTheme.containerMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          label: l10n.adminBackToCompanies,
                          variant: AppButtonVariant.ghost,
                          icon: Icons.arrow_back,
                          dense: true,
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.adminCompanies),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _companyName(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      // Same tab strip as the Company Configuration module —
                      // ModuleTabBar was extracted from it rather than a second
                      // tab style being invented here.
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) => ModuleTabBar(
                          labels: [l10n.adminCompanyTabUsers],
                          activeIndex: _tabController.index,
                          onTap: _tabController.animateTo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            AdminCompanyUsersBody(companyId: widget.companyId),
                          ],
                        ),
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
