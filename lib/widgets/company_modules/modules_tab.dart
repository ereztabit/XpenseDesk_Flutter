import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../providers/company_modules_provider.dart';
import '../../providers/company_provider.dart';
import '../../services/company_modules_service.dart';
import '../../utils/company_modules_utils.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import 'module_card.dart';
import 'module_page.dart';

/// Company settings → Modules tab (FS-1010, manager only). Shows the module
/// list, or one module's page in place (not a route) with a back link.
class ModulesTab extends ConsumerStatefulWidget {
  const ModulesTab({super.key});

  @override
  ConsumerState<ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends ConsumerState<ModulesTab> {
  CompanyModuleKey? _openModule;
  final Set<CompanyModuleKey> _busy = {};

  Future<void> _toggle(CompanyModule module, bool on) async {
    final l10n = AppLocalizations.of(context)!;
    if (!on) {
      final confirmed = await ConfirmChoiceDialog.show(
        context,
        title: '${l10n.modulesOffTitlePrefix} ${moduleName(l10n, module.key)}?',
        body: l10n.modulesOffBody,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.modulesOffConfirm,
        confirmVariant: AppButtonVariant.destructive,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _busy.add(module.key));
    try {
      await ref
          .read(companyModulesActionsProvider)
          .setModuleEnabled(module.key, on);
      if (!on && mounted && _openModule == module.key) {
        setState(() => _openModule = null);
      }
    } on CompanyModulesException catch (e) {
      _showError(companyModulesErrorText(l10n, e.errorCode));
    } catch (_) {
      _showError(l10n.modulesErrorGeneric);
    } finally {
      if (mounted) setState(() => _busy.remove(module.key));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyProvider);
    if (!company.hasValue) {
      return Padding(
        padding: const EdgeInsets.all(64),
        child: Center(
          child: company.hasError
              ? Text(AppLocalizations.of(context)!.modulesErrorGeneric)
              : const CircularProgressIndicator(),
        ),
      );
    }
    final modules = ref.watch(companyModulesProvider);
    final open = modules.where((m) => m.key == _openModule).firstOrNull;

    if (open != null) {
      return ModulePage(
        module: open,
        busy: _busy.contains(open.key),
        onBack: () => setState(() => _openModule = null),
        onToggle: (on) => _toggle(open, on),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final module in modules) ...[
          ModuleCard(
            module: module,
            busy: _busy.contains(module.key),
            onToggle: (on) => _toggle(module, on),
            onConfigure: () => setState(() => _openModule = module.key),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
