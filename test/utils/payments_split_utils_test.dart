// FS-1020 PC-8: payments totals never net; rows of any sheet type parse
// null-safely (pre-PC-8 payloads still work).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/company_module.dart';
import 'package:xpensedesk_flutter/models/paged_payments.dart';
import 'package:xpensedesk_flutter/models/payment_direction.dart';
import 'package:xpensedesk_flutter/models/payment_report_row.dart';
import 'package:xpensedesk_flutter/models/payment_status.dart';
import 'package:xpensedesk_flutter/models/payments_summary.dart';
import 'package:xpensedesk_flutter/utils/payments_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/payments_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));

Map<String, dynamic> _json(String id, double amount, {String? direction}) => {
      'expenseSheetId': id,
      'amount': amount,
      'direction': ?direction,
      'paymentStatus': 'AwaitingPayment',
    };

PaymentReportRow _row(String id, double amount) =>
    PaymentReportRow.fromJson(_json(id, amount));

void main() {
  group('PaymentReportRow.fromJson', () {
    test('pre-PC-8 payload: Monthly, Pay, no budget', () {
      final r = _row('a', 100);
      expect(r.sheetType, CompanyModuleKey.monthly);
      expect(r.direction, PaymentDirection.pay);
      expect(r.budgetNumber, isNull);
      expect(r.isAwaiting, isTrue);
    });

    test('budget collect row', () {
      final r = PaymentReportRow.fromJson({
        ..._json('b', -250, direction: 'Collect'),
        'sheetType': 'PettyCash',
        'budgetNumber': 1004,
        'budgetName': 'Events',
      });
      expect(r.sheetType, CompanyModuleKey.pettyCash);
      expect(r.isCollect, isTrue);
      expect(r.magnitude, 250);
      expect(paymentBudgetText(r), 'Events #1004');
    });

    test('missing direction falls back to the sign', () {
      expect(_row('c', -5).direction, PaymentDirection.collect);
    });
  });

  group('PaymentTotals', () {
    final rows = [
      _row('a', 100),
      _row('b', -30),
      _row('c', 50),
      _row('d', -20),
    ];

    test('splits by direction, magnitudes', () {
      final t = PaymentTotals.of(rows);
      expect(t.payCount, 2);
      expect(t.payAmount, 150);
      expect(t.collectCount, 2);
      expect(t.collectAmount, 50);
      expect(t.count, 4);
    });

    test('selection totals only count selected ids', () {
      final t = PaymentsSelectionUtils.totalsFor(rows, {'a', 'b'});
      expect(t.payAmount, 100);
      expect(t.collectAmount, 30);
    });
  });

  group('paymentSelectionText', () {
    test('selection line keeps the old wording without collect', () {
      expect(
        paymentSelectionText(en, const PaymentTotals(payCount: 1, payAmount: 9),
            locale: 'en', currencyCode: null),
        '1 sheet of 9.00',
      );
    });
  });

  test('status text by direction', () {
    expect(
        paymentStatusText(en, PaymentStatus.processed,
            direction: PaymentDirection.collect),
        'Charged');
    expect(
        paymentStatusText(en, PaymentStatus.processed,
            direction: PaymentDirection.pay),
        'Paid');
    expect(paymentStatusText(en, PaymentStatus.processed), 'Processed');
  });

  test('PagedPayments.withoutSheets adjusts each side apart', () {
    final paged = PagedPayments.fromJson({
      'items': [_json('a', 100), _json('b', -30, direction: 'Collect')],
      'totalCount': 2,
      'pageTotalAmount': 100,
      'grandTotalAmount': 100,
      'payCount': 1,
      'collectCount': 1,
      'pageCollectAmount': 30,
      'grandCollectAmount': 30,
    });
    final after = paged.withoutSheets({'b'});
    expect(after.items.length, 1);
    expect(after.grandTotalAmount, 100);
    expect(after.collectCount, 0);
    expect(after.grandCollectAmount, 0);
  });

  test('PaymentsSummary parses without collect fields', () {
    final s = PaymentsSummary.fromJson(
        {'awaitingCount': 3, 'awaitingTotalAmount': 10});
    expect(s.awaitingCollectCount, 0);
    expect(s.awaitingCollectAmount, 0);
    expect(s.hasAny, isTrue);
  });
}
