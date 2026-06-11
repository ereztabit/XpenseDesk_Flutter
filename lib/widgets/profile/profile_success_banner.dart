import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Green confirmation banner shown after a successful profile save.
class ProfileSuccessBanner extends StatelessWidget {
  const ProfileSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }
}
