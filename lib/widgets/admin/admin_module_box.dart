import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// One module tile on the admin landing page.
class AdminModuleBox extends StatefulWidget {
  const AdminModuleBox({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<AdminModuleBox> createState() => _AdminModuleBoxState();
}

class _AdminModuleBoxState extends State<AdminModuleBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: _hovered ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 22, color: AppTheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.adminModuleOpen,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
