import 'screen_imports.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/admin/admin_module_grid.dart';

/// Admin shell landing page (`/admin`) — a grid of module boxes.
///
/// Touches no company-scoped provider and issues no company API call: the
/// platform company the admin session carries is an internal implementation
/// detail, not a tenant.
class AdminLandingScreen extends ConsumerStatefulWidget {
  const AdminLandingScreen({super.key});

  @override
  ConsumerState<AdminLandingScreen> createState() => _AdminLandingScreenState();
}

class _AdminLandingScreenState extends ConsumerState<AdminLandingScreen>
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  maxWidth: AppTheme.containerMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminLandingHeading,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminLandingSubheading,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      const AdminModuleGrid(),
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
