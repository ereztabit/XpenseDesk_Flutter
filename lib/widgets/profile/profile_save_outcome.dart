/// Result of a profile save, returned by a `ProfileEditor.onSave` callback.
/// Lets each parent (self vs admin) own its service call + exception mapping
/// while the editor stays a pure, reusable form.
class ProfileSaveOutcome {
  final bool success;

  /// 'UsersGovIdInvalidFormat' or 'UsersGovIdAlreadyExists' — rendered inline
  /// on the gov-ID field by the editor.
  final String? govIdErrorCode;

  /// Any other (already-resolved) error message — rendered in the error alert.
  final String? generalError;

  const ProfileSaveOutcome._(
      this.success, this.govIdErrorCode, this.generalError);
  const ProfileSaveOutcome.success() : this._(true, null, null);
  const ProfileSaveOutcome.govIdError(String code) : this._(false, code, null);
  const ProfileSaveOutcome.error(String message) : this._(false, null, message);
}
