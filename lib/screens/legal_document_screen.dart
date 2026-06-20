import 'screen_imports.dart';

enum LegalDocumentType { privacy, terms }

/// Placeholder screen for the Privacy Policy / Terms of Service legal documents.
/// Real content is tracked separately (see docs/current-work.md "general
/// environment"); until then this shows a "coming soon" notice so the menu
/// entries navigate somewhere meaningful.
class LegalDocumentScreen extends ConsumerStatefulWidget {
  final LegalDocumentType docType;

  const LegalDocumentScreen({super.key, required this.docType});

  @override
  ConsumerState<LegalDocumentScreen> createState() =>
      _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends ConsumerState<LegalDocumentScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.docType == LegalDocumentType.privacy
        ? l10n.privacyPolicy
        : l10n.termsOfService;

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
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.foreground,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.legalContentComingSoon,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppTheme.mutedForeground),
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
