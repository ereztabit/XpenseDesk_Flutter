import 'screen_imports.dart';
import '../utils/app_navigator.dart';
import '../widgets/admin/admin_companies_body.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/app_button.dart';

/// Companies list (`/admin/companies`) — admin module #1.
///
/// Reads `GET /api/admin/companies` only. Read-only: search and sort are
/// client-side over that one payload; there is no drill-down, export or write
/// of any kind.
///
/// Deviates from the standard `Expanded -> SingleChildScrollView ->
/// ConstrainedContent` scaffold, as the Cycle Expenses report does and for the
/// same reason: the table has a sticky header and scrolls its own rows, so it
/// needs a bounded height rather than an unbounded scrolling page.
class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  ConsumerState<AdminCompaniesScreen> createState() =>
      _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends ConsumerState<AdminCompaniesScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

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
                          dense: true,
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.adminLanding),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminCompaniesHeading,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      const Expanded(child: AdminCompaniesBody()),
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
