import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/navigation_guard_provider.dart';
import '../language_switcher.dart';

/// LoginHeader - Simple header for login/signup pages
/// 
/// Layout: Language Switcher (left) | Logo (right)
class LoginHeader extends ConsumerWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.containerMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Language Switcher
                const LanguageSwitcher(),

                // Spacer
                const Spacer(),

                // Logo
                GestureDetector(
                  onTap: () async {
                    final guard = ref.read(navigationGuardProvider);
                    final canLeave = guard != null ? await guard() : true;
                    if (canLeave && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
