import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../company_modules/module_switch.dart';

/// One company setting in the admin Configuration tab's "Features" card
/// (bulk upload UI/UX guide §7.2): title, description, an optional status
/// line, and the switch at the row's end. [busy] shows a spinner; a null
/// [onChanged] shows the switch disabled (another flag is saving). The switch
/// is [ModuleSwitch], so hover and disabled states match the Modules tab.
class AdminFeatureToggleRow extends StatelessWidget {
  const AdminFeatureToggleRow({
    super.key,
    required this.title,
    required this.description,
    this.statusLine,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final String description;
  final String? statusLine;
  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(description,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.mutedForeground)),
              if (statusLine != null) ...[
                const SizedBox(height: 6),
                Text(statusLine!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedForeground)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        ModuleSwitch(
          value: value,
          busy: busy,
          onChanged: onChanged,
          semanticLabel: title,
        ),
      ],
    );
  }
}
