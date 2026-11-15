import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../providers/company_modules_provider.dart';
import '../../services/company_modules_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/company_modules_utils.dart';
import 'module_section_card.dart';
import 'module_switch.dart';

/// Module settings. Petty Cash has one: "Allow negative balance". The other
/// modules have none yet.
class ModuleSettingsCard extends ConsumerStatefulWidget {
  const ModuleSettingsCard({super.key, required this.module});

  final CompanyModule module;

  @override
  ConsumerState<ModuleSettingsCard> createState() => _ModuleSettingsCardState();
}

class _ModuleSettingsCardState extends ConsumerState<ModuleSettingsCard> {
  bool _busy = false;

  Future<void> _setAllowNegative(bool allow) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(companyModulesActionsProvider)
          .setAllowNegativeBalance(allow);
    } on CompanyModulesException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(companyModulesErrorText(l10n, e.errorCode))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.modulesErrorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPettyCash = widget.module.key == CompanyModuleKey.pettyCash;

    return ModuleSectionCard(
      title: l10n.modulesSettings,
      child: isPettyCash
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.modulesAllowNegative,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.modulesAllowNegativeHint,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ModuleSwitch(
                  value: widget.module.allowNegativeBalance ?? false,
                  busy: _busy,
                  semanticLabel: l10n.modulesAllowNegative,
                  onChanged: _setAllowNegative,
                ),
              ],
            )
          : Text(
              l10n.modulesNoSettings,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
    );
  }
}
