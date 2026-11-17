import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Level-2 Back of the sheet-type bar: neutral outlined round button, never a
/// primary fill (it must read as "back"). Desktop shows the word; mobile is a
/// 44px icon-only circle. The arrow follows the reading direction.
class SheetNavBackButton extends StatefulWidget {
  const SheetNavBackButton({
    super.key,
    required this.onTap,
    this.showLabel = true,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  State<SheetNavBackButton> createState() => _SheetNavBackButtonState();
}

class _SheetNavBackButtonState extends State<SheetNavBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.sheetNavBack,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsetsDirectional.only(
              start: widget.showLabel ? 12 : 0,
              end: widget.showLabel ? 16 : 0,
            ),
            decoration: BoxDecoration(
              color: _hovered ? AppTheme.muted : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.borderMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppTheme.foreground,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.sheetNavBack,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
