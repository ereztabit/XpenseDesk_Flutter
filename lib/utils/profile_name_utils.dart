import '../generated/l10n/app_localizations.dart';

/// The user's full name rule, shared by the profile form and the employee
/// first sign-in: required, at most 50 characters, letters (Latin or Hebrew),
/// spaces and hyphens only.
class ProfileNameValidator {
  ProfileNameValidator._();

  static final RegExp _allowed = RegExp(r'^[a-zA-Z֐-׿\s-]+$');
  static final RegExp _digit = RegExp(r'\d');

  /// The error to show, or null when valid.
  static String? validate(AppLocalizations l10n, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.nameRequired;
    if (v.length > 50) return l10n.nameMaxLength;
    if (!_allowed.hasMatch(v)) {
      return _digit.hasMatch(v) ? l10n.nameNoNumbers : l10n.nameOnlyLetters;
    }
    return null;
  }
}
