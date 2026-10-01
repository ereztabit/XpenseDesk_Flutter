import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_configuration.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_format_utils.dart';
import '../../utils/app_navigator.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import '../profile/profile_section_card.dart';
import 'admin_feature_toggle_row.dart';
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
  bool _saving = false;

  Future<void> _toggle(bool enable) async {
    final l10n = AppLocalizations.of(context)!;
    final prefix = enable
        ? l10n.adminConfigTurnOnConfirmPrefix
        : l10n.adminConfigTurnOffConfirmPrefix;
    final confirmed = await ConfirmChoiceDialog.show(
      context,
      title: '$prefix ${widget.companyName}?',
      body: enable ? null : l10n.adminConfigTurnOffConfirmNote,
      cancelLabel: l10n.cancel,
      confirmLabel: enable ? l10n.adminConfigTurnOn : l10n.adminConfigTurnOff,
      confirmVariant:
          enable ? AppButtonVariant.primary : AppButtonVariant.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref
          .read(adminServiceProvider)
          .updateCompanyConfiguration(
              companyId: widget.companyId, isBulkUploadEnabled: enable);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _saving = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminConfigSaved)));
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.errorCode == 'AdminCompanyNotFound') {
        _backToCompanies();
        return;
      }
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.adminConfigSaveError)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
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

    final Widget row = async.when(
      loading: () => AdminFeatureToggleRow(
        title: l10n.adminConfigBulkUploadTitle,
        description: l10n.adminConfigBulkUploadDesc,
        statusLine: '',
        value: false,
        busy: true,
        onChanged: (_) {},
      ),
      error: (_, _) => Row(
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
      data: (loaded) {
        final config = _saved ?? loaded;
        return AdminFeatureToggleRow(
          title: l10n.adminConfigBulkUploadTitle,
          description: l10n.adminConfigBulkUploadDesc,
          statusLine: _statusLine(l10n, config),
          value: config.isBulkUploadEnabled,
          busy: _saving,
          onChanged: _toggle,
        );
      },
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
                children: [row],
              ),
              const SizedBox(height: 16),
              AdminFreePlanCard(
                companyId: widget.companyId,
                companyName: widget.companyName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
