// Payments list (owner, 2026-11-18): money to charge reads negative, and the
// caption above the list shows the signed net of what is listed.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/payment_report_row.dart';
import 'package:xpensedesk_flutter/utils/payments_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/payments_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));
const _lri = '\u2066', _pdi = '\u2069';

PaymentReportRow _row(String id, double amount) => PaymentReportRow.fromJson({
  'expenseSheetId': id,
  'amount': amount,
  'paymentStatus': 'AwaitingPayment',
});

void main() {
  test('a row to charge reads negative, kept left-to-right', () {
    expect(
      paymentRowAmountText(_row('a', -60), 'en-US', null),
      '$_lri-60.00$_pdi',
    );
    expect(paymentRowAmountText(_row('b', 50), 'en-US', null), '50.00');
  });

  test('net: plain when positive, minus only when negative', () {
    PaymentTotals t(List<double> a) =>
        PaymentTotals.of([for (var i = 0; i < a.length; i++) _row('$i', a[i])]);
    expect(paymentNetText(t([150, -30]), 'en-US', null), '120.00');
    expect(paymentNetText(t([20, -50]), 'en-US', null), '$_lri-30.00$_pdi');
    expect(paymentNetText(t([30, -30]), 'en-US', null), '0.00');
  });

  test('total row: label with count, signed net', () {
    expect(paymentsTotalLabelText(en, 4), 'Total · 4 sheets');
    expect(paymentsTotalLabelText(en, 1), 'Total · 1 sheet');
    expect(paymentsTotalLabelText(he, 4), 'סה״כ · 4 גליונות');
    final t = PaymentTotals.of([_row('a', 527.24), _row('b', -60)]);
    expect(paymentNetText(t, 'en-US', null), '467.24');
    final one = PaymentTotals.of([_row('a', 10)]);
    expect(
      paymentNetText(one, 'en-US', null),
      '10.00',
      reason: 'nothing to charge: no sign',
    );
  });

  test(
    'sort by sheet type: Monthly first, then budgets by name and number',
    () {
      PaymentReportRow r(String id, String type, [String? name, int? n]) =>
          PaymentReportRow.fromJson({
            'expenseSheetId': id,
            'amount': 1,
            'paymentStatus': 'AwaitingPayment',
            'sheetType': type,
            'budgetName': ?name,
            'budgetNumber': ?n,
          });
      final sorted = PaymentsSortUtils.sort(
        [
          r('b2', 'PettyCash', 'Tour', 2),
          r('m', 'Monthly'),
          r('a', 'PettyCash', 'Events', 9),
          r('b1', 'PettyCash', 'Tour', 1),
        ],
        PaymentsSortField.sheetType,
        ascending: true,
      );
      expect(sorted.map((x) => x.expenseSheetId), ['m', 'a', 'b1', 'b2']);
    },
  );

  test('bulk action reads Process N sheets', () {
    expect(paymentProcessCountText(en, 2), 'Process 2 sheets');
    expect(paymentProcessCountText(en, 1), 'Process 1 sheet');
    expect(paymentProcessCountText(he, 2), 'טיפול 2 גליונות');
  });

  test('pending badge and charge wording', () {
    expect(en.paymentStatusPending, 'Pending');
    expect(en.paymentsDirectionToCollect, 'To charge');
    expect(he.paymentsDirectionToCollect, 'לגבות');
  });
}
