import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../bulk_upload/confirm_choice_dialog.dart';
import 'ai_row_action.dart';

/// The Profiles-table action cell: Clone, Set as default, Archive / Restore as
/// 32x32 icon actions in a fixed-width column (the admin table pattern). Archive
/// is shown greyed, with the reason, while the server would refuse it.
class AiProfileActions extends ConsumerWidget {
  const AiProfileActions({super.key, required this.row, required this.onClone, required this.onChanged});

  /// The action column's width - three icons and their gaps.
  static const double width = 108;

  final AdminAiProfileRow row;
  final VoidCallback onClone;
  final VoidCallback onChanged;

  Future<void> _run(BuildContext context, Future<void> Function() call, String done) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await call();
      if (!context.mounted) return;
      showAdminAiSnack(context, done);
      onChanged();
    } catch (e) {
      if (context.mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  Future<void> _confirmThen(
    BuildContext context,
    String title,
    String body,
    String confirm,
    Future<void> Function() call,
    String done,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ConfirmChoiceDialog.show(
      context,
      title: '$title: ${row.name}',
      body: body,
      cancelLabel: l10n.cancel,
      confirmLabel: confirm,
    );
    if (ok && context.mounted) await _run(context, call, done);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(adminAiProfilesServiceProvider);
    final block = aiArchiveBlock(row);
    final id = row.aiProfileId;

    return SizedBox(
      width: width,
      child: Row(
        children: [
          if (!row.isArchived) ...[
            AiRowAction(icon: Icons.copy_outlined, tooltip: l10n.adminAiClone, onPressed: onClone),
            const SizedBox(width: 4),
            AiRowAction(
              icon: Icons.star_outline,
              tooltip: l10n.adminAiSetDefault,
              onPressed: canSetAiDefault(row)
                  ? () => _confirmThen(
                      context,
                      l10n.adminAiSetDefaultTitle,
                      l10n.adminAiSetDefaultBody,
                      l10n.adminAiSetDefault,
                      () => service.setDefault(id),
                      l10n.adminAiDefaultSet,
                    )
                  : null,
              disabledTooltip: row.isDefault ? l10n.adminAiStatusDefault : null,
            ),
            const SizedBox(width: 4),
            AiRowAction(
              icon: Icons.archive_outlined,
              tooltip: l10n.adminAiArchive,
              disabledTooltip: switch (block) {
                AdminAiArchiveBlock.isDefault => l10n.adminAiArchiveBlockedDefault,
                AdminAiArchiveBlock.hasCompanies => l10n.adminAiArchiveBlockedCompanies,
                null => null,
              },
              onPressed: block == null
                  ? () => _confirmThen(
                      context,
                      l10n.adminAiArchiveTitle,
                      l10n.adminAiArchiveBody,
                      l10n.adminAiArchive,
                      () => service.archive(id),
                      l10n.adminAiArchivedToast,
                    )
                  : null,
            ),
          ] else
            AiRowAction(
              icon: Icons.unarchive_outlined,
              tooltip: l10n.adminAiRestore,
              onPressed: () => _run(context, () => service.restore(id), l10n.adminAiRestoredToast),
            ),
        ],
      ),
    );
  }
}
