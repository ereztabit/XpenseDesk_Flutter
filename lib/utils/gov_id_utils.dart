/// Validation for the employee government ID (תעודת זהות).
///
/// `govId` is ALWAYS a String (leading zeros are significant), digits-only,
/// max 40 characters, and optional — blank/null is valid (the field can be
/// left empty, and an empty submission clears the value server-side).
/// Uniqueness is decided server-side (409 `UsersGovIdAlreadyExists`); this
/// helper only covers the format + length rules the client can check up front.
class GovIdValidator {
  GovIdValidator._();

  static const int maxLength = 40;
  static final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

  /// True when [value] is a structurally valid gov ID, or blank (optional).
  static bool isValid(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return true;
    return v.length <= maxLength && _digitsOnly.hasMatch(v);
  }
}
