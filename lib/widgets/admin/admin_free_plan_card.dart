import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_free_plan.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import '../profile/profile_section_card.dart';

/// The admin company page's "Billing" card (FS-1008): sets or clears the free
/// plan — paid in full, no card, nothing at the payment provider (design
/// partners). One button, whichever applies; both ask first, since either one
/// changes what a real customer can do.
///
/// The current state comes from the companies overview row (`isFreePlan`),
/// already loaded behind the admin shell; after an action the server's answer
/// wins and the overview is refreshed quietly behind it.
class AdminFreePlanCard extends ConsumerStatefulWidget {
  const AdminFreePlanCard({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  ConsumerState<AdminFreePlanCard> createState() => _AdminFreePlanCardState();
}

class _AdminFreePlanCardState extends ConsumerState<AdminFreePlanCard> {
  /// The server's answer to the last action — newer than the overview row.
  AdminFreePlan? _saved;
  bool _saving = false;

  bool? _rowIsFreePlan() {
    final rows = ref.watch(adminCompaniesProvider).asData?.value;
    if (rows == null) return null;
    for (final row in rows) {
      if (row.companyId == widget.companyId) return row.isFreePlan;
    }
    return null;
  }

  Future<void> _change({required bool set}) async {
    final l10n = AppLocalizations.of(context)!;
    final prefix = set
        ? l10n.adminFreePlanSetConfirmPrefix
        : l10n.adminFreePlanClearConfirmPrefix;
    final confirmed = await ConfirmChoiceDialog.show(
      context,
      title: '$prefix ${widget.companyName}?',
      body: set ? l10n.adminFreePlanSetConfirmNote : l10n.adminFreePlanClearConfirmNote,
      cancelLabel: l10n.cancel,
      confirmLabel: set ? l10n.adminFreePlanSet : l10n.adminFreePlanClear,
      confirmVariant:
          set ? AppButtonVariant.primary : AppButtonVariant.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(adminServiceProvider);
    String message;
    try {
      final saved = set
          ? await service.setFreePlan(widget.companyId)
          : await service.clearFreePlan(widget.companyId);
      _saved = saved;
      message = set ? l10n.adminFreePlanSetDone : l10n.adminFreePlanClearDone;
    } on AdminException catch (e) {
      switch (e.errorCode) {
        case 'AdminCompanyNotFound':
          if (mounted) _backToCompanies();
          return;
        // Someone else got there first — the refusal says which state it is in.
        case 'AdminFreePlanAlreadySet':
          _saved = const AdminFreePlan(isFreePlan: true);
          message = l10n.adminFreePlanAlreadySet;
        case 'AdminFreePlanNotSet':
          _saved = const AdminFreePlan(isFreePlan: false);
          message = l10n.adminFreePlanNotSet;
        case 'AdminFreePlanCompanyPays':
          message = l10n.adminFreePlanCompanyPays;
        default:
          message = l10n.adminFreePlanError;
      }
    } catch (_) {
      message = l10n.adminFreePlanError;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    // The companies table shows the free plan too; keep it in step.
    ref.read(adminCompaniesProvider.notifier).refreshQuietly();
  }

  void _backToCompanies() {
    ref.read(adminCompaniesProvider.notifier).refresh();
    Navigator.of(context).pushReplacementNamed(AppRoutes.adminCompanies);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFreePlan = _saved?.isFreePlan ?? _rowIsFreePlan();

    return ProfileSectionCard(
      icon: Icons.workspace_premium_outlined,
      title: l10n.adminConfigBillingTitle,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.adminFreePlanTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l10n.adminFreePlanDesc,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.mutedForeground)),
                  const SizedBox(height: 6),
                  Text(
                    isFreePlan == null
                        ? ''
                        : isFreePlan
                            ? l10n.adminFreePlanOnStatus
                            : l10n.adminFreePlanOffStatus,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AppButton(
              label: isFreePlan == true
                  ? l10n.adminFreePlanClear
                  : l10n.adminFreePlanSet,
              variant: isFreePlan == true
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              dense: true,
              isLoading: _saving,
              onPressed: isFreePlan == null
                  ? null
                  : () => _change(set: !isFreePlan),
            ),
          ],
        ),
      ],
    );
  }
}
