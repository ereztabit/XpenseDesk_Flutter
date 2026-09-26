import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_navigator.dart';
import '../app_button.dart';
import 'admin_destroy_company_dialog.dart';

/// FS-1005: "Destroy company" in the company module's title row.
///
/// Disabled until the company name is known — the confirmation is typed against
/// it, and the name arrives with the companies list. After a successful destroy
/// the list is reloaded and the admin is sent back to it, since the module they
/// were in no longer has a company behind it.
class AdminDestroyCompanyButton extends ConsumerWidget {
  const AdminDestroyCompanyButton({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final destroyed = await AdminDestroyCompanyDialog.show(
      context,
      companyId: companyId,
      companyName: companyName,
    );
    if (!destroyed || !context.mounted) return;

    ref.read(adminCompaniesProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminDestroyCompanyDone)),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.adminCompanies);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AppButton(
      label: l10n.adminDestroyCompany,
      variant: AppButtonVariant.destructive,
      icon: Icons.delete_forever,
      dense: true,
      onPressed: companyName.isEmpty ? null : () => _onPressed(context, ref),
    );
  }
}
