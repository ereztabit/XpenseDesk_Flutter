import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../action_icon_button.dart';

/// A table-row action (Receipt AI): the admin tables' [ActionIconButton], or -
/// when [onPressed] is null - the same 32x32 icon greyed out, with the reason
/// as its tooltip. Stateless, so it is safe inside a table's selection area.
class AiRowAction extends StatelessWidget {
  const AiRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.disabledTooltip,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Why it is disabled; defaults to [tooltip].
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    if (onPressed != null) {
      return ActionIconButton(icon: icon, tooltip: tooltip, color: AppTheme.primary, onPressed: onPressed);
    }
    return Tooltip(
      message: disabledTooltip ?? tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: AppTheme.mutedForeground.withAlpha(110)),
      ),
    );
  }
}
