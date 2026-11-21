import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../app_button.dart';
import 'ai_profile_dropdown.dart';

/// Max lengths - the server limits (docs/api-guides/receipt-ai-api-guide.md).
const int kAiProfileNameMaxLength = 100;
const int kAiProfileDescriptionMaxLength = 400;

/// New profile = a copy of another profile's published version. Pops `true`
/// when one was created.
class AiNewProfileDialog extends ConsumerStatefulWidget {
  const AiNewProfileDialog({super.key, required this.profiles, this.fromId});

  final List<AdminAiProfileRow> profiles;
  final int? fromId;

  static Future<bool> show(BuildContext context, {required List<AdminAiProfileRow> profiles, int? fromId}) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AiNewProfileDialog(profiles: profiles, fromId: fromId),
      ) ??
      false;

  @override
  ConsumerState<AiNewProfileDialog> createState() => _AiNewProfileDialogState();
}

class _AiNewProfileDialogState extends ConsumerState<AiNewProfileDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  late int? _fromId = widget.fromId ?? defaultAiProfileId(widget.profiles);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final fromId = _fromId;
    if (fromId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(adminAiProfilesServiceProvider)
          .createProfile(
            name: _name.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            fromAiProfileId: fromId,
          );
      if (!mounted) return;
      showAdminAiSnack(context, l10n.adminAiCreated);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    return AlertDialog(
      title: Text(l10n.adminAiNewProfile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminAiNewProfileBody, style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
            const SizedBox(height: 16),
            Text(l10n.adminAiFieldName, style: label),
            const SizedBox(height: 6),
            TextField(controller: _name, maxLength: kAiProfileNameMaxLength, onChanged: (_) => setState(() {})),
            Text(l10n.adminAiFieldDescription, style: label),
            const SizedBox(height: 6),
            TextField(controller: _description, maxLength: kAiProfileDescriptionMaxLength),
            Text(l10n.adminAiFieldCopyFrom, style: label),
            const SizedBox(height: 6),
            AiProfileDropdown(
              profiles: widget.profiles,
              selectedId: _fromId,
              width: 420,
              onSelected: (id) => setState(() => _fromId = id),
            ),
            const SizedBox(height: 6),
            Text(l10n.adminAiCopyFromHint, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: l10n.adminAiCreateProfile,
          isLoading: _saving,
          onPressed: _name.text.trim().isEmpty || _fromId == null || _saving ? null : _create,
        ),
      ],
    );
  }
}
