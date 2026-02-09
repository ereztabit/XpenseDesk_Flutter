import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Language Switcher - Select dropdown for switching between English and Hebrew
/// 
/// Design:
/// - Trigger: Flag emoji + short label ("EN" / "עב") + dropdown arrow
/// - Size: 32px height (h-8), ~76px wide
/// - Style: Borderless, transparent background, hover state with white/10 tint
/// - Dropdown: Flag + full language name, z-index 100
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEnglish = currentLocale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      elevation: 8,
      tooltip: '', // Disable tooltip
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
      onSelected: (String languageCode) {
        ref.read(localeProvider.notifier).setLocale(Locale(languageCode));
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇺🇸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.english,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isEnglish ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isEnglish) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 16, color: AppTheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'he',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇮🇱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.hebrew,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: !isEnglish ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (!isEnglish) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 16, color: AppTheme.primary),
              ],
            ],
          ),
        ),
      ],
      child: _LanguageSwitcherButton(isEnglish: isEnglish),
    );
  }
}

/// Language Switcher Button - The trigger button that displays current language
class _LanguageSwitcherButton extends StatefulWidget {
  final bool isEnglish;

  const _LanguageSwitcherButton({required this.isEnglish});

  @override
  State<_LanguageSwitcherButton> createState() => _LanguageSwitcherButtonState();
}

class _LanguageSwitcherButtonState extends State<_LanguageSwitcherButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _isHovering 
              ? Colors.white.withAlpha(25) // white/10 tint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEnglish ? '🇺🇸' : '🇮🇱',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              widget.isEnglish ? 'EN' : 'עב',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.foreground.withAlpha(179), // 70% opacity
            ),
          ],
        ),
      ),
    );
  }
}
