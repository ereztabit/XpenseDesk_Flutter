import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../theme/app_theme.dart';
import '../../utils/company_modules_utils.dart';
import 'module_icon_tile.dart';
import 'module_switch.dart';

/// Module page header: icon, name, On/Off badge and the module switch (same
/// rules as the card — locked modules show it disabled).
class ModulePageHeader extends StatelessWidget {
  const ModulePageHeader({
    super.key,
    required this.module,
    required this.busy,
    required this.onToggle,
  });

  final CompanyModule module;
  final bool busy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = moduleName(l10n, module.key);
    final on = module.isEnabled;

    return Row(
      children: [
        ModuleIconTile(icon: moduleIcon(module.key)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: on ? AppTheme.primary : AppTheme.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            on ? l10n.modulesOn : l10n.modulesOff,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? AppTheme.primaryForeground : AppTheme.mutedForeground,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ModuleSwitch(
          value: on,
          busy: busy,
          semanticLabel: name,
          onChanged: module.isLocked ? null : onToggle,
        ),
      ],
    );
  }
}
