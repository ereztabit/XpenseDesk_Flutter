/// The user's free receipts (FS-1007 S3, api-guide §11.1): how many expenses a
/// user on trial may have for the whole trial - every expense uses one, and so
/// does each file of a batch still being read. [isLimited] false means no
/// limit applies (a paid plan) and none of this UI shows.
class FreeReceipts {
  const FreeReceipts({
    required this.isLimited,
    required this.allowance,
    required this.used,
    required this.left,
  });

  /// No limit — what the client assumes until the server says otherwise, so
  /// nothing is capped or hidden by mistake.
  static const unlimited =
      FreeReceipts(isLimited: false, allowance: 0, used: 0, left: 0);

  /// "Low" from this many left (UI/UX guide §9.2): the meter turns amber.
  static const lowThreshold = 2;

  final bool isLimited;
  final int allowance;
  final int used;
  final int left;

  bool get isUsedUp => isLimited && left <= 0;
  bool get isLow => isLimited && left <= lowThreshold;

  /// The meter's fill: what is used, as a share of the allowance (0..1). It
  /// starts empty and grows with every receipt used.
  double get usedFraction =>
      allowance <= 0 ? 0 : (used / allowance).clamp(0.0, 1.0);

  factory FreeReceipts.fromJson(Map<String, dynamic> json) => FreeReceipts(
        isLimited: json['isLimited'] as bool? ?? false,
        allowance: json['allowance'] as int? ?? 0,
        used: json['used'] as int? ?? 0,
        left: json['left'] as int? ?? 0,
      );
}
