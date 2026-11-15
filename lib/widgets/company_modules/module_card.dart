import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../theme/app_theme.dart';
import '../../utils/company_modules_utils.dart';
import '../app_button.dart';
import 'module_icon_tile.dart';
import 'module_section_card.dart';
import 'module_switch.dart';

/// One module on the Modules list: icon, name, description, on/off switch,
/// and a Configure button while the module is on. Turning a module on does
/// not open its page — only Configure does.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.module,
    required this.busy,
    required this.onToggle,
    required this.onConfigure,
  });

  final CompanyModule module;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = moduleName(l10n, module.key);

    return ModuleSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleIconTile(icon: moduleIcon(module.key)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moduleDescription(l10n, module.key),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    if (module.isLocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.modulesLockedHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ModuleSwitch(
                value: module.isEnabled,
                busy: busy,
                semanticLabel: name,
                onChanged: module.isLocked ? null : onToggle,
              ),
            ],
          ),
          if (module.isEnabled) ...[
            const SizedBox(height: 12),
            AppButton(
              label: l10n.modulesConfigure,
              variant: AppButtonVariant.normal,
              icon: Icons.settings_outlined,
              onPressed: onConfigure,
            ),
          ],
        ],
      ),
    );
  }
}
