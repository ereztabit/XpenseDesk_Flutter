/// FS-1020 PC-8: which way a settlement goes, from the holder's side.
/// `Pay` = the company pays the employee; `Collect` = the company collects
/// from them (an unspent budget). Wire values are the API's `direction`.
enum PaymentDirection {
  pay('Pay'),
  collect('Collect');

  final String wireName;

  const PaymentDirection(this.wireName);

  /// Parses the wire value; null/unknown falls back to the sign of [amount]
  /// (older payloads carry no direction and are always Pay).
  static PaymentDirection parse(String? wireName, double amount) {
    for (final d in values) {
      if (d.wireName == wireName) return d;
    }
    return fromAmount(amount) ?? PaymentDirection.pay;
  }

  /// Signed settlement amount -> direction; null when nothing is owed.
  static PaymentDirection? fromAmount(double amount) {
    if (amount > 0) return PaymentDirection.pay;
    if (amount < 0) return PaymentDirection.collect;
    return null;
  }
}
