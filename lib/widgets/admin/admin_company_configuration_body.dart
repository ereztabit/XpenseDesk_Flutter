import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_configuration.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_feature_flag_utils.dart';
import '../../utils/admin_format_utils.dart';
import '../../utils/app_navigator.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import '../profile/profile_section_card.dart';
import 'admin_feature_toggle_row.dart';
import 'admin_sheet_exports_card.dart';
import 'admin_company_ai_profile_card.dart';
import 'admin_free_plan_card.dart';

/// The admin company page's Configuration tab (FS-1007, bulk upload UI/UX
/// guide §7): a "Features" card with one row per company setting. Flipping a
/// switch changes what a real customer sees, so it always asks first. Below it,
/// the "Billing" card with the free plan (FS-1008, [AdminFreePlanCard]).
class AdminCompanyConfigurationBody extends ConsumerStatefulWidget {
  const AdminCompanyConfigurationBody({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  ConsumerState<AdminCompanyConfigurationBody> createState() =>
      _AdminCompanyConfigurationBodyState();
}

class _AdminCompanyConfigurationBodyState
    extends ConsumerState<AdminCompanyConfigurationBody> {
  /// The PUT response, which is newer than the loaded value once it exists.
  AdminCompanyConfiguration? _saved;

  /// The switch being saved; every switch is locked while one saves, so two
  /// PUTs never race on the same row.
  AdminFeatureFlag? _saving;

  Future<void> _toggle(AdminFeatureFlag flag, bool enable) async {
    final l10n = AppLocalizations.of(context)!;
    final prefix = flag.confirmPrefix(l10n, enable: enable);
    final confirmed = await ConfirmChoiceDialog.show(
      context,
      title: '$prefix ${widget.companyName}?',
      body: enable ? null : flag.turnOffNote(l10n),
      cancelLabel: l10n.cancel,
      confirmLabel: enable ? l10n.adminConfigTurnOn : l10n.adminConfigTurnOff,
      confirmVariant:
          enable ? AppButtonVariant.primary : AppButtonVariant.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = flag);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref
          .read(adminServiceProvider)
          .updateCompanyConfiguration(
              companyId: widget.companyId, flag: flag, enabled: enable);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _saving = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminConfigSaved)));
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() => _saving = null);
      if (e.errorCode == 'AdminCompanyNotFound') {
        _backToCompanies();
        return;
      }
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.adminConfigSaveError)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = null);
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.adminConfigSaveError)));
    }
  }

  void _backToCompanies() {
    ref.read(adminCompaniesProvider.notifier).refresh();
    Navigator.of(context).pushReplacementNamed(AppRoutes.adminCompanies);
  }

  String _statusLine(AppLocalizations l10n, AdminCompanyConfiguration c) {
    final at = c.updatedAt;
    if (at == null) return l10n.adminConfigNeverChanged;
    return '${l10n.adminConfigLastChanged} '
        '${at.toIsraelTime().toDateTimeStamp()}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async =
        ref.watch(adminCompanyConfigurationProvider(widget.companyId));

    ref.listen(adminCompanyConfigurationProvider(widget.companyId),
        (_, next) {
      final e = next.error;
      if (e is AdminException && e.errorCode == 'AdminCompanyNotFound') {
        _backToCompanies();
      }
    });

    Widget rowFor(AdminFeatureFlag flag, AdminCompanyConfiguration? config) =>
        AdminFeatureToggleRow(
          title: flag.title(l10n),
          description: flag.description(l10n),
          value: config?.valueOf(flag) ?? false,
          busy: config == null || _saving == flag,
          // null while another flag saves: the switch shows disabled
          // instead of looking live and ignoring the click
          onChanged: _saving != null || config == null
              ? null
              : (on) => _toggle(flag, on),
        );

    // The server stamps one updatedAt for the whole configuration row, so the
    // "Last changed" line is shown once, under all the switches.
    List<Widget> rows(AdminCompanyConfiguration? config) => [
          for (final (i, flag) in AdminFeatureFlag.values.indexed) ...[
            if (i > 0) const Divider(height: 32, color: AppTheme.border),
            rowFor(flag, config),
          ],
          if (config != null) ...[
            const SizedBox(height: 16),
            Text(_statusLine(l10n, config),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground)),
          ],
        ];

    final List<Widget> content = async.when(
      loading: () => rows(null),
      error: (_, _) => [
        Row(
          children: [
            Expanded(
              child: Text(l10n.adminConfigLoadError,
                  style: const TextStyle(color: AppTheme.destructive)),
            ),
            AppButton(
              label: l10n.retry,
              variant: AppButtonVariant.normal,
              dense: true,
              onPressed: () => ref.invalidate(
                  adminCompanyConfigurationProvider(widget.companyId)),
            ),
          ],
        ),
      ],
      data: (loaded) => rows(_saved ?? loaded),
    );

    return SingleChildScrollView(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileSectionCard(
                icon: Icons.tune,
                title: l10n.adminConfigFeaturesTitle,
                children: content,
              ),
              const SizedBox(height: 16), // FS-1026: the company's AI profile
              AdminCompanyAiProfileCard(companyId: widget.companyId, companyName: widget.companyName),
              const SizedBox(height: 16),
              AdminFreePlanCard(
                companyId: widget.companyId,
                companyName: widget.companyName,
              ),
              // PC-5: under Billing, as its own section (owner QA, 2026-11-19).
              const SizedBox(height: 16),
              AdminSheetExportsCard(companyId: widget.companyId),
            ],
          ),
        ),
      ),
    );
  }
}
