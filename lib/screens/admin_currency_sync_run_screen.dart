import 'screen_imports.dart';
import '../utils/app_navigator.dart';
import '../widgets/admin/admin_currency_sync_run_body.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/app_button.dart';

/// One currency sync (`/admin/currencies/runs/{id}`) — FS-1019. The id is in the
/// path, so refresh and bookmarking land on the same run.
class AdminCurrencySyncRunScreen extends ConsumerStatefulWidget {
  const AdminCurrencySyncRunScreen({super.key, required this.syncRunId});

  final int syncRunId;

  @override
  ConsumerState<AdminCurrencySyncRunScreen> createState() =>
      _AdminCurrencySyncRunScreenState();
}

class _AdminCurrencySyncRunScreenState
    extends ConsumerState<AdminCurrencySyncRunScreen> with FormBehaviorMixin {
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
                          label: l10n.adminCurrencyRunBack,
                          variant: AppButtonVariant.ghost,
                          icon: Icons.arrow_back,
                          dense: true,
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.adminCurrencies),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminCurrencyRunHeading,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AdminCurrencySyncRunBody(syncRunId: widget.syncRunId),
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
