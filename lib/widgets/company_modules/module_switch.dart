import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// On/off switch for a module or a module setting. Shows a spinner while the
/// write is in flight; [onChanged] null disables it (a locked module).
///
/// Material's [Switch] mirrors itself under an RTL [Directionality], so the
/// thumb sits at the reading-direction end when on — no manual flip needed.
class ModuleSwitch extends StatelessWidget {
  const ModuleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.busy = false,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool busy;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 44,
      child: busy
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Semantics(
              label: semanticLabel,
              child: Switch(
                value: value,
                // Explicit state colours: with only `activeTrackColor`, the M3
                // hover thumb blends into the track and a locked (disabled) on
                // switch looks exactly like an active one.
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (!states.contains(WidgetState.selected)) return null;
                  return states.contains(WidgetState.disabled)
                      ? AppTheme.primary.withAlpha(102)
                      : AppTheme.primary;
                }),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppTheme.card
                      : null,
                ),
                onChanged: onChanged,
              ),
            ),
    );
  }
}
