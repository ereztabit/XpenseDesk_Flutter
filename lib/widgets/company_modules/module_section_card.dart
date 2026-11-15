import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bordered white card used by the Modules tab. [padded] false lets the child
/// (the categories list) draw edge-to-edge row dividers; [title] and
/// [trailing] form an optional header row.
class ModuleSectionCard extends StatelessWidget {
  const ModuleSectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padded = true,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(
            padding: padded
                ? EdgeInsetsDirectional.fromSTEB(
                    20,
                    title == null ? 16 : 0,
                    20,
                    16,
                  )
                : EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}
