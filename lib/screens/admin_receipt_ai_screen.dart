import 'screen_imports.dart';
import '../utils/app_navigator.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/admin/receipt_ai/ai_companies_body.dart';
import '../widgets/admin/receipt_ai/ai_profiles_body.dart';
import '../widgets/admin/receipt_ai/ai_usage_body.dart';
import '../widgets/app_button.dart';
import '../widgets/admin/receipt_ai/ai_tab_strip.dart';

/// Receipt AI (`/admin/receipt-ai/{tab}`) - admin module (FS-1026): AI
/// profiles, which company runs on which profile, and usage.
///
/// Bounded-height scaffold like the companies screen: the profile and company
/// tables have sticky headers and scroll their own rows.
class AdminReceiptAiScreen extends ConsumerStatefulWidget {
  const AdminReceiptAiScreen({super.key, this.initialTab});

  /// Path segment (`profiles`, `companies`, `usage`); unknown = the first tab.
  final String? initialTab;

  @override
  ConsumerState<AdminReceiptAiScreen> createState() => _AdminReceiptAiScreenState();
}

class _AdminReceiptAiScreenState extends ConsumerState<AdminReceiptAiScreen>
    with FormBehaviorMixin, SingleTickerProviderStateMixin {
  /// Tab order is the URL contract - append, never insert.
  static const List<String> _tabs = [
    AppRoutes.adminAiTabProfiles,
    AppRoutes.adminAiTabCompanies,
    AppRoutes.adminAiTabUsage,
  ];

  late final TabController _tabController;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    final index = _tabs.indexOf(widget.initialTab ?? '');
    _tabController = TabController(length: _tabs.length, initialIndex: index < 0 ? 0 : index, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                          label: l10n.adminBackToModules,
                          variant: AppButtonVariant.ghost,
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.adminLanding),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.adminAiHeading, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(l10n.adminAiSubheading, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) => AiTabStrip(
                          labels: [l10n.adminAiTabProfiles, l10n.adminAiTabCompanies, l10n.adminAiTabUsage],
                          activeIndex: _tabController.index,
                          onTap: _tabController.animateTo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [AiProfilesBody(), AiCompaniesBody(), AiUsageBody()],
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
