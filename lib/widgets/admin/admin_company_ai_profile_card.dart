import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_receipt_ai_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_ai_display_utils.dart';
import '../../utils/admin_ai_utils.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import '../profile/profile_section_card.dart';
import 'receipt_ai/ai_profile_dropdown.dart';

/// Company > Configuration: the company's AI profile (FS-1026). A change asks
/// first and applies from the company's next scan. Same move call as the
/// Receipt AI > Companies tab.
class AdminCompanyAiProfileCard extends ConsumerStatefulWidget {
  const AdminCompanyAiProfileCard({super.key, required this.companyId, required this.companyName});

  final String companyId;
  final String companyName;

  @override
  ConsumerState<AdminCompanyAiProfileCard> createState() => _AdminCompanyAiProfileCardState();
}

class _AdminCompanyAiProfileCardState extends ConsumerState<AdminCompanyAiProfileCard> {
  bool _saving = false;

  /// Bumped to rebuild the dropdown on the current profile after a cancel.
  int _rev = 0;

  Future<void> _choose(int? profileId, int? current) async {
    if (profileId == null || profileId == current) return;
    final l10n = AppLocalizations.of(context)!;
    final profiles = ref.read(adminAiProfilesProvider).asData?.value ?? const [];
    final target = aiProfileById(profiles, profileId);
    if (target == null) return;
    final label = adminAiProfileLabel(target.aiProfileId, target.name);

    final ok = await ConfirmChoiceDialog.show(context,
        title: '${l10n.adminAiSwitchTitle}: ${widget.companyName}',
        body: '${l10n.adminAiSwitchBody} $label ${adminAiVersion(target.publishedVersionNumber)}.',
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.adminAiSwitchConfirm);
    if (!ok || !mounted) {
      if (mounted) setState(() => _rev++); // the dropdown goes back to the current profile
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(adminAiUsageServiceProvider).moveCompanies(aiProfileId: profileId, companyIds: [widget.companyId]);
      if (!mounted) return;
      showAdminAiSnack(context, l10n.adminAiSwitched);
      ref.invalidate(adminAiCompaniesProvider);
      ref.invalidate(adminAiProfilesProvider);
    } catch (e) {
      if (mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companies = ref.watch(adminAiCompaniesProvider);
    final profiles = ref.watch(adminAiProfilesProvider).asData?.value ?? const [];
    final company = aiCompanyById(companies.asData?.value ?? const [], widget.companyId);

    return ProfileSectionCard(
      icon: Icons.receipt_long_outlined,
      title: l10n.adminAiCardTitle,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.adminAiCardProfile, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(l10n.adminAiCardDescription, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
              ]),
            ),
            AiProfileDropdown(
              key: ValueKey('company-ai-${company?.aiProfileId}-$_saving-$_rev'),
              profiles: activeAiProfiles(profiles),
              selectedId: company?.aiProfileId,
              width: 280,
              onSelected: _saving || company == null ? (_) {} : (id) => _choose(id, company.aiProfileId),
            ),
          ],
        ),
        if (company != null) ...[
          const SizedBox(height: 16),
          Text(
            '${adminAiLtr('${adminAiProfileLabel(company.aiProfileId, company.aiProfileName)} ${adminAiVersion(company.publishedVersionNumber)}')}'
            ' · ${l10n.adminAiCardSince} ${adminAiDate(company.onProfileSince)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
          ),
        ],
        if (companies.hasError)
          Text(l10n.adminAiLoadError, style: const TextStyle(color: AppTheme.destructive)),
      ],
    );
  }
}
