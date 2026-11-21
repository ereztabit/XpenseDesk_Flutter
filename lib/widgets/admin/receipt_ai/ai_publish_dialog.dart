import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/admin_ai_review_utils.dart';
import '../../app_button.dart';

/// Publish the draft: what changed against the published version, and how
/// many companies switch with their next scan. Pops `true` when published.
class AiPublishDialog extends ConsumerStatefulWidget {
  const AiPublishDialog({super.key, required this.detail});

  final AdminAiProfileDetail detail;

  static Future<bool> show(BuildContext context, {required AdminAiProfileDetail detail}) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AiPublishDialog(detail: detail),
      ) ??
      false;

  @override
  ConsumerState<AiPublishDialog> createState() => _AiPublishDialogState();
}

class _AiPublishDialogState extends ConsumerState<AiPublishDialog> {
  bool _publishing = false;

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _publishing = true);
    try {
      await ref.read(adminAiProfilesServiceProvider).publish(widget.detail.aiProfileId);
      if (!mounted) return;
      showAdminAiSnack(context, l10n.adminAiPublishedToast);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.detail.draft;
    final (:gptChanged, :fields) = aiDraftChanges(widget.detail);

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      title: Text(
        '${l10n.adminAiPublishTitle} ${adminAiVersion(draft?.versionNumber)}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminAiPublishBody, style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
            const SizedBox(height: 14),
            line(l10n.adminAiTabGpt, gptChanged ? l10n.adminAiChanged : l10n.adminAiNoChange),
            line(
              l10n.adminAiTabMistral,
              fields.isEmpty ? l10n.adminAiNoChange : '${fields.length} — ${fields.join(', ')}',
            ),
            line(l10n.adminAiPublishCompanies, '${widget.detail.companyCount}'),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(label: l10n.adminAiPublish, isLoading: _publishing, onPressed: _publishing ? null : _publish),
      ],
    );
  }
}
