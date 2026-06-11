import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Bordered white card used for each profile section. Optional header
/// (icon + title); cards without one are titled by the host screen.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.children,
    this.icon,
    this.title,
  });

  final List<Widget> children;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null && title != null) ...[
              Row(
                children: [
                  Icon(icon, color: AppTheme.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    title!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Shared input decoration for the boxed profile text fields (name, gov ID).
InputDecoration profileFieldDecoration({String? hintText, String? errorText}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hintText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: border(AppTheme.border),
    enabledBorder: border(AppTheme.border),
    focusedBorder: border(AppTheme.primary, 2),
    errorBorder: border(AppTheme.destructive),
    focusedErrorBorder: border(AppTheme.destructive, 2),
    counterText: '',
    errorText: errorText,
  );
}
