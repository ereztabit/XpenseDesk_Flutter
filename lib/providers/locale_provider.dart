import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing app locale
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('he');

  void setLocale(Locale locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
