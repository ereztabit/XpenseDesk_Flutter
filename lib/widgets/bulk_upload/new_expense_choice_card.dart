import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One large choice in the mobile "New expense" sheet (UI/UX guide §2.2).
///
/// Colours are fixed on purpose — the mock shipped a bug here: pressed/hover
/// only swaps to a muted background with a light primary border, text and icon
/// keep their colours, and focus is a ring only. Never a filled accent.
class NewExpenseChoiceCard extends StatefulWidget {
  const NewExpenseChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<NewExpenseChoiceCard> createState() => _NewExpenseChoiceCardState();
}

class _NewExpenseChoiceCardState extends State<NewExpenseChoiceCard> {
  bool _active = false;
  bool _focused = false;

  void _setActive(bool v) {
    if (_active != v) setState(() => _active = v);
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: _setActive,
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setActive(true),
        onTapUp: (_) => _setActive(false),
        onTapCancel: () => _setActive(false),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _active ? AppTheme.muted : AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppTheme.primary
                  : _active
                      ? AppTheme.primary.withAlpha(77)
                      : AppTheme.border,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 28, color: AppTheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground)),
                    const SizedBox(height: 2),
                    Text(widget.description,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
