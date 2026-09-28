import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One company setting in the admin Configuration tab's "Features" card
/// (bulk upload UI/UX guide §7.2): title, description, status line, and the
/// switch at the row's end. [busy] shows a spinner and locks the switch.
class AdminFeatureToggleRow extends StatelessWidget {
  const AdminFeatureToggleRow({
    super.key,
    required this.title,
    required this.description,
    required this.statusLine,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final String description;
  final String statusLine;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

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
              const SizedBox(height: 6),
              Text(statusLine,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.mutedForeground)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 64,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Switch(
                  value: value,
                  activeTrackColor: AppTheme.primary,
                  onChanged: onChanged,
                ),
        ),
      ],
    );
  }
}
