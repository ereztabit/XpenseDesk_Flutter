import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../models/admin_ai_usage.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../app_button.dart';
import '../../bulk_upload/confirm_choice_dialog.dart';
import 'ai_profile_dropdown.dart';

/// Shown while companies are selected: "N selected · Move to [profile] · Move ·
/// Clear selection". Move asks first, listing the companies.
class AiCompaniesSelectionBar extends ConsumerStatefulWidget {
  const AiCompaniesSelectionBar({super.key, required this.profiles});

  final List<AdminAiProfileRow> profiles;

  @override
  ConsumerState<AiCompaniesSelectionBar> createState() => _AiCompaniesSelectionBarState();
}

class _AiCompaniesSelectionBarState extends ConsumerState<AiCompaniesSelectionBar> {
  int? _target;
  bool _moving = false;

  Future<void> _move() async {
    final l10n = AppLocalizations.of(context)!;
    final target = aiProfileById(widget.profiles, _target);
    if (target == null) return;
    final selected = ref.read(adminAiSelectedCompaniesProvider);
    // A few names, not all of them - 40 selected would not fit the dialog.
    final picked = aiFirstItems(
      (ref.read(adminAiCompaniesProvider).asData?.value ?? const <AdminAiCompanyRow>[])
          .where((c) => selected.contains(c.companyId))
          .toList(),
    );
    final names = [
      for (final c in picked.shown) '• ${c.companyName} — ${adminAiProfileLabel(c.aiProfileId, c.aiProfileName)}',
      if (picked.more > 0) '+${picked.more} ${l10n.adminAiMore}',
    ].join('\n');
    final label = adminAiProfileLabel(target.aiProfileId, target.name);
    final ok = await ConfirmChoiceDialog.show(
      context,
      title: '${l10n.adminAiMoveTitle}: $label',
      body:
          '${selected.length} ${l10n.adminAiSelected}. '
          '${l10n.adminAiMoveBody} $label ${adminAiVersion(target.publishedVersionNumber)}.\n\n$names',
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.adminAiMove,
    );
    if (!ok || !mounted) return;

    setState(() => _moving = true);
    try {
      final moved = await ref
          .read(adminAiUsageServiceProvider)
          .moveCompanies(aiProfileId: target.aiProfileId, companyIds: selected.toList());
      if (!mounted) return;
      showAdminAiSnack(context, adminAiCount(moved, l10n.adminAiMovedToastOne, l10n.adminAiMovedToast));
      ref.read(adminAiSelectedCompaniesProvider.notifier).set(const {});
      ref.invalidate(adminAiCompaniesProvider);
      ref.invalidate(adminAiProfilesProvider);
    } catch (e) {
      if (mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(adminAiSelectedCompaniesProvider).length;

    return Container(
      width: double.infinity, // spans the content width, like the table under it
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      child: LayoutBuilder(
        builder: (context, c) {
          final stacked = c.maxWidth < 600;
          final caption = Text(
            '$count ${l10n.adminAiSelected} · ${l10n.adminAiMoveTo}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          );
          final dropdown = AiProfileDropdown(
            profiles: widget.profiles,
            selectedId: _target,
            hint: l10n.adminAiChooseProfile,
            width: stacked ? c.maxWidth : 260,
            onSelected: (id) => setState(() => _target = id),
          );
          final move = AppButton(
            label: l10n.adminAiMove,
            variant: AppButtonVariant.normal,
            icon: Icons.drive_file_move_outline,
            onPressed: _target == null || _moving ? null : _move,
          );
          final clear = AppButton(
            label: l10n.adminAiClearSelection,
            variant: AppButtonVariant.normal,
            icon: Icons.close,
            onPressed: () => ref.read(adminAiSelectedCompaniesProvider.notifier).set(const {}),
          );
          // Phone: everything full width, buttons at their natural height (a
          // pinned 40px clipped the labels). Desktop: one line, buttons held to
          // the dropdown's 40px.
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [caption, const SizedBox(height: 8), dropdown, const SizedBox(height: 8), move,
                const SizedBox(height: 8), clear],
            );
          }
          return Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              caption,
              dropdown,
              SizedBox(height: 40, child: move),
              SizedBox(height: 40, child: clear),
            ],
          );
        },
      ),
    );
  }
}
