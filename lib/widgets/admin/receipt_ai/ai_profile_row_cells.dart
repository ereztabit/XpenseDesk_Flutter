import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/app_navigator.dart';
import '../../action_icon_button.dart';
import '../admin_status_pill.dart';
import 'ai_profile_actions.dart';

/// One Profiles-table row as [AdminFixedTable] cells, in column order.
/// Stateless cells - the table's rows live in a selection area. Without
/// [showLastChanged] the "Last changed" cell is left out (narrow table).
List<Widget> aiProfileRowCells(
  BuildContext context,
  AdminAiProfileRow row, {
  required VoidCallback onClone,
  required VoidCallback onChanged,
  bool showLastChanged = true,
}) {
  final l10n = AppLocalizations.of(context)!;
  final (statusLabel, statusColor) = adminAiProfileStatusLabel(l10n, aiProfileStatus(row));
  const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);
  const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

  return [
    Text(
      '${row.aiProfileId}',
      style: cell.copyWith(fontWeight: FontWeight.w700, color: AppTheme.mutedForeground),
    ),
    Row(
      children: [
        ActionIconButton(
          icon: Icons.edit_outlined,
          tooltip: l10n.adminAiOpenProfile,
          color: AppTheme.primary,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminAiProfile(row.aiProfileId)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.name,
                overflow: TextOverflow.ellipsis,
                style: cell.copyWith(fontWeight: FontWeight.w600),
              ),
              if ((row.description ?? '').isNotEmpty)
                Text(row.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
            ],
          ),
        ),
      ],
    ),
    AdminStatusPill(label: statusLabel, color: statusColor),
    Text('${row.companyCount}', style: cell),
    Text(adminAiVersion(row.publishedVersionNumber), style: cell),
    row.draftVersionNumber == null
        ? const Text('—', style: muted)
        : AdminStatusPill(
            label: '${adminAiVersion(row.draftVersionNumber)} ${l10n.adminAiDraftSuffix}',
            color: AppTheme.amber,
          ),
    if (showLastChanged)
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(adminAiDateTime(row.updatedAt), style: cell),
          if ((row.updatedByName ?? '').isNotEmpty) Text(row.updatedByName!, style: muted),
        ],
      ),
    AiProfileActions(row: row, onClone: onClone, onChanged: onChanged),
  ];
}
