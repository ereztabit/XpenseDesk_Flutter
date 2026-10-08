import '../../generated/l10n/app_localizations.dart';

/// Result of a profile save, returned by a `ProfileEditor.onSave` callback.
/// Lets each parent (self vs admin) own its service call + exception mapping
/// while the editor stays a pure, reusable form.
class ProfileSaveOutcome {
  final bool success;

  /// 'UsersGovIdInvalidFormat' or 'UsersGovIdAlreadyExists' — rendered inline
  /// on the gov-ID field by the editor.
  final String? govIdErrorCode;

  /// 'UsersPhoneInvalidFormat' or 'UsersPhoneAlreadyExists' (FS-1009) —
  /// rendered inline on the phone field by the editor.
  final String? phoneErrorCode;

  /// Any other (already-resolved) error message — rendered in the error alert.
  final String? generalError;

  const ProfileSaveOutcome._(
      this.success, this.govIdErrorCode, this.phoneErrorCode, this.generalError);
  const ProfileSaveOutcome.success() : this._(true, null, null, null);
  const ProfileSaveOutcome.govIdError(String code)
      : this._(false, code, null, null);
  const ProfileSaveOutcome.phoneError(String code)
      : this._(false, null, code, null);
  const ProfileSaveOutcome.error(String message)
      : this._(false, null, null, message);

  /// The inline message for the gov-ID field, or null.
  String? govIdErrorText(AppLocalizations l10n) => switch (govIdErrorCode) {
        null => null,
        'UsersGovIdAlreadyExists' => l10n.govIdAlreadyExists,
        _ => l10n.govIdInvalidFormat,
      };

  /// The inline message for the phone field, or null.
  String? phoneErrorText(AppLocalizations l10n) => switch (phoneErrorCode) {
        null => null,
        'UsersPhoneAlreadyExists' => l10n.phoneAlreadyExists,
        _ => l10n.phoneInvalidFormat,
      };

  /// Maps a server error code to the field outcome it belongs to, or null when
  /// it is not a field error.
  static ProfileSaveOutcome? forFieldError(String? code) => switch (code) {
        'UsersGovIdInvalidFormat' ||
        'UsersGovIdAlreadyExists' =>
          ProfileSaveOutcome.govIdError(code!),
        'UsersPhoneInvalidFormat' ||
        'UsersPhoneAlreadyExists' =>
          ProfileSaveOutcome.phoneError(code!),
        _ => null,
      };
}
