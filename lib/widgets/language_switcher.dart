import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../generated/l10n/app_localizations.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEnglish = currentLocale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      onSelected: (String languageCode) {
        ref.read(localeProvider.notifier).setLocale(Locale(languageCode));
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              if (isEnglish) const Icon(Icons.check, size: 18),
              if (isEnglish) const SizedBox(width: 8),
              Text(l10n.english),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'he',
          child: Row(
            children: [
              if (!isEnglish) const Icon(Icons.check, size: 18),
              if (!isEnglish) const SizedBox(width: 8),
              Text(l10n.hebrew),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18),
            const SizedBox(width: 6),
            Text(
              isEnglish ? 'EN' : 'HE',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
