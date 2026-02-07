import 'package:flutter/material.dart';
import 'dart:ui';
import 'language_switcher.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.95),
            border: const Border(
              bottom: BorderSide(
                color: AppTheme.border,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              LanguageSwitcher(),
            ],
          ),
        ),
      ),
    );
  }
}
