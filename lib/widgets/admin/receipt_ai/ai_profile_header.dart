import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../services/excel_export_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/app_navigator.dart';
import '../../app_button.dart';
import 'ai_status_badge.dart';
import 'ai_button_row.dart';
import 'ai_import_dialog.dart';

/// Profile editor header: back, `#n` + name + status, description, and the
/// ReceiptLab file actions (Import -> a draft, Download -> the published text).
class AiProfileHeader extends ConsumerWidget {
  const AiProfileHeader({
    super.key,
    required this.profileId,
    required this.detail,
    required this.isDirty,
    required this.onImported,
  });

  final int profileId;
  final AdminAiProfileDetail? detail;

  /// Unsaved editor text - Import would replace it, so it waits.
  final bool isDirty;
  final VoidCallback onImported;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final file = await ref.read(adminAiProfilesServiceProvider).downloadFile(profileId);
      ExcelExportService.downloadBytes(utf8.encode(file.content), file.fileName, 'text/plain;charset=utf-8');
      if (context.mounted) showAdminAiSnack(context, l10n.adminAiDownloaded);
    } catch (e) {
      if (context.mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final d = detail;
    final row = d == null
        ? null
        : AdminAiProfileRow(
            aiProfileId: d.aiProfileId,
            name: d.name,
            isDefault: d.isDefault,
            isArchived: d.isArchived,
            companyCount: d.companyCount,
          );
    final status = row == null ? null : adminAiProfileStatusLabel(l10n, aiProfileStatus(row));

    final title = Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '#$profileId',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.mutedForeground),
        ),
        Text(d?.name ?? '', style: Theme.of(context).textTheme.headlineMedium),
        if (status != null && d != null)
          AiStatusBadge(label: '${status.$1} · ${d.companyCount} ${l10n.adminAiColCompanies}', color: status.$2),
      ],
    );
    final buttons = [
      Tooltip(
        message: isDirty ? l10n.adminAiSaveFirst : '',
        child: AppButton(
          label: l10n.adminAiImport,
          variant: AppButtonVariant.normal,
          icon: Icons.upload_file_outlined,
          onPressed: d == null || d.isArchived || isDirty
              ? null
              : () async {
                  if (await AiImportDialog.show(context, profileId: profileId)) onImported();
                },
        ),
      ),
      AppButton(
        label: l10n.adminAiDownload,
        variant: AppButtonVariant.normal,
        icon: Icons.download_outlined,
        onPressed: d == null ? null : () => _download(context, ref),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: l10n.adminAiBackToReceiptAi,
          variant: AppButtonVariant.ghost,
          icon: Icons.arrow_back,
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.adminAiTab(AppRoutes.adminAiTabProfiles)),
        ),
        const SizedBox(height: 8),
        // Wide: title and status at the start, the file buttons at the end of
        // the same line, vertically centred. Narrow: the buttons go below.
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 900
              ? Row(
                  children: [
                    Expanded(child: title),
                    AiButtonRow(children: buttons),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    AiButtonRow(children: buttons),
                  ],
                ),
        ),
        if ((d?.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(d!.description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
