// Every Payments export gets its own file name (owner, 2026-11-18): a full
// local timestamp, so a new download never replaces the last one.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/payments_export_utils.dart';

void main() {
  test('file name carries date and time to the second', () {
    expect(
      paymentsExportFileName(
          'payments-selected', DateTime(2026, 11, 18, 9, 5, 7)),
      'payments-selected-2026-11-18_09-05-07.xlsx',
    );
  });

  test('two downloads a second apart get different names', () {
    final a = paymentsExportFileName(
        'payments-report', DateTime(2026, 11, 18, 20, 15, 42));
    final b = paymentsExportFileName(
        'payments-report', DateTime(2026, 11, 18, 20, 15, 43));
    expect(a, isNot(b));
  });
}
