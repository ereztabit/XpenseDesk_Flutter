import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../app_button.dart';
import 'categories_card.dart';
import 'module_page_header.dart';
import 'module_settings_card.dart';

/// One module's page inside the Modules tab: back link, header with the
/// on/off switch, settings, and the categories editor.
class ModulePage extends StatelessWidget {
  const ModulePage({
    super.key,
    required this.module,
    required this.busy,
    required this.onBack,
    required this.onToggle,
  });

  final CompanyModule module;
  final bool busy;
  final VoidCallback onBack;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton(
            label: l10n.modulesBack,
            variant: AppButtonVariant.ghost,
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: 12),
        ModulePageHeader(module: module, busy: busy, onToggle: onToggle),
        const SizedBox(height: 16),
        ModuleSettingsCard(module: module),
        const SizedBox(height: 16),
        CategoriesCard(module: module.key),
      ],
    );
  }
}
