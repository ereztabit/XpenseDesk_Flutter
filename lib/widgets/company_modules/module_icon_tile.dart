import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 40×40 tinted square holding a module's icon (module card + module page).
class ModuleIconTile extends StatelessWidget {
  const ModuleIconTile({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: AppTheme.primary),
    );
  }
}
