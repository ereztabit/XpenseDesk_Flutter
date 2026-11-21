import 'screen_imports.dart';
import '../providers/admin_receipt_ai_provider.dart';
import '../utils/admin_ai_display_utils.dart';
import '../utils/admin_ai_review_utils.dart';
import '../utils/app_navigator.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/admin/receipt_ai/ai_scan_fields_card.dart';
import '../widgets/admin/receipt_ai/ai_scan_header.dart';
import '../widgets/admin/receipt_ai/ai_scan_images_card.dart';
import '../widgets/admin/receipt_ai/ai_scan_json_card.dart';

/// One AI-read expense for review (`/admin/receipt-ai/usage/scans/{id}`),
/// FS-1026: the images, what each model read, what the expense holds; Verified,
/// or Save to expense (the expense changes and an internal audit is kept).
/// Walks the scan list it was opened from (Previous / Next unreviewed).
class AdminAiScanScreen extends ConsumerStatefulWidget {
  const AdminAiScanScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  ConsumerState<AdminAiScanScreen> createState() => _AdminAiScanScreenState();
}

class _AdminAiScanScreenState extends ConsumerState<AdminAiScanScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  void _goTo(String? expenseId) {
    if (expenseId == null) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.adminAiScan(expenseId));
  }

  /// After a review: mark it, then open the next unreviewed scan of the list.
  void _reviewed() {
    final l10n = AppLocalizations.of(context)!;
    final reviewed = {...ref.read(adminAiReviewedIdsProvider), widget.expenseId};
    ref.read(adminAiReviewedIdsProvider.notifier).set(reviewed);
    ref.invalidate(adminAiUsageProvider);
    ref.invalidate(adminAiScansProvider);
    final next = nextUnreviewedId(ref.read(adminAiScanQueueProvider), widget.expenseId, reviewed);
    if (next == null) {
      showAdminAiSnack(context, l10n.adminAiAllReviewed);
      ref.invalidate(adminAiScanReviewProvider(widget.expenseId));
      return;
    }
    _goTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiScanReviewProvider(widget.expenseId));
    final queue = ref.watch(adminAiScanQueueProvider);
    final reviewed = ref.watch(adminAiReviewedIdsProvider);
    final review = async.asData?.value;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AdminHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ConstrainedContent(
                  maxWidth: AppTheme.containerMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AiScanHeader(
                        review: review,
                        unreviewedLeft: aiUnreviewedCount(queue, reviewed),
                        onPrevious: previousId(queue, widget.expenseId) == null
                            ? null
                            : () => _goTo(previousId(queue, widget.expenseId)),
                        onNext: nextUnreviewedId(queue, widget.expenseId, reviewed) == null
                            ? null
                            : () => _goTo(nextUnreviewedId(queue, widget.expenseId, reviewed)),
                      ),
                      const SizedBox(height: 16),
                      if (review == null)
                        async.hasError
                            ? Text(
                                adminAiErrorMessage(l10n, async.error!),
                                style: const TextStyle(color: AppTheme.destructive),
                              )
                            : const Center(child: CircularProgressIndicator())
                      else ...[
                        // Full width, top to bottom: images, what the AI read, JSON.
                        AiScanImagesCard(review: review),
                        const SizedBox(height: 16),
                        AiScanFieldsCard(key: ValueKey(review.expenseId), review: review, onReviewed: _reviewed),
                        const SizedBox(height: 16),
                        AiScanJsonCard(review: review),
                      ],
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
