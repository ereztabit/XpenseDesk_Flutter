/// A sheet's payment status — a server-computed dimension that exists only on
/// approved sheets with a payable amount. The client never sets
/// AwaitingPayment directly; it only processes (and reverts).
///
/// Wire convention (matches the rest of the API): query params use the int id
/// ([queryId]); responses and write bodies use the string name ([wireName]).
enum PaymentStatus {
  awaitingPayment(1, 'AwaitingPayment'),
  processed(2, 'Processed');

  final int queryId;
  final String wireName;

  const PaymentStatus(this.queryId, this.wireName);

  /// Parses a response value ("AwaitingPayment" / "Processed").
  /// Returns null for null/unknown values so new server states degrade
  /// gracefully instead of crashing list parsing.
  static PaymentStatus? tryParse(String? wireName) {
    for (final status in PaymentStatus.values) {
      if (status.wireName == wireName) return status;
    }
    return null;
  }
}
