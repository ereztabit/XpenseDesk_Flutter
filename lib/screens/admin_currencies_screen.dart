import 'screen_imports.dart';
import '../utils/app_navigator.dart';
import '../widgets/admin/admin_currencies_body.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/app_button.dart';

/// Currencies (`/admin/currencies`) — admin module (FS-1019).
///
/// Bank of Israel rate freshness per tracked currency, the recent syncs, and
/// Sync now. Same bounded-height scaffold as the companies screen: the tables
/// have sticky headers and scroll their own rows.
class AdminCurrenciesScreen extends ConsumerStatefulWidget {
  const AdminCurrenciesScreen({super.key});

  @override
  ConsumerState<AdminCurrenciesScreen> createState() => _AdminCurrenciesScreenState();
}

class _AdminCurrenciesScreenState extends ConsumerState<AdminCurrenciesScreen>
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
                        l10n.adminCurrenciesHeading,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const Expanded(child: AdminCurrenciesBody()),
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
