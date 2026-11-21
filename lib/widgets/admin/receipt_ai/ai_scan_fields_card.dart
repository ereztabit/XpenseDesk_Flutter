import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../utils/admin_ai_display_utils.dart';
import 'ai_scan_fields_form.dart';

/// The scan review's fields card: [AiScanFieldsForm] wired to the API -
/// Save to expense (the expense changes, an internal audit is kept) and
/// Verified. [onReviewed] runs after either succeeds.
class AiScanFieldsCard extends ConsumerStatefulWidget {
  const AiScanFieldsCard({super.key, required this.review, required this.onReviewed});

  final AdminAiScanReview review;
  final VoidCallback onReviewed;

  @override
  ConsumerState<AiScanFieldsCard> createState() => _AiScanFieldsCardState();
}

class _AiScanFieldsCardState extends ConsumerState<AiScanFieldsCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() call, String done) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await call();
      if (!mounted) return;
      showAdminAiSnack(context, done);
      widget.onReviewed();
    } catch (e) {
      if (mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(adminAiUsageServiceProvider);
    final id = widget.review.expenseId;

    return AiScanFieldsForm(
      review: widget.review,
      busy: _busy,
      onSave: (values) => _run(() => service.correct(id, values), l10n.adminAiSavedToExpense),
      onVerify: () => _run(() => service.verify(id), l10n.adminAiMarkedVerified),
    );
  }
}
