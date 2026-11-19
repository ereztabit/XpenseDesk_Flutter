import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_section_card.dart';
import 'admin_clear_exports_button.dart';

/// PC-5: the company's stored sheet exports, as its own section under Billing
/// in the Configuration tab (owner QA, 2026-11-19) - what they are, and the
/// "Clear stored sheet exports" action.
class AdminSheetExportsCard extends StatelessWidget {
  const AdminSheetExportsCard({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileSectionCard(
      icon: Icons.picture_as_pdf_outlined,
      title: l10n.adminSheetExportsTitle,
      children: [
        Text(
          l10n.adminSheetExportsDesc,
          style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AdminClearExportsButton(companyId: companyId),
        ),
      ],
    );
  }
}
