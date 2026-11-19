// PC-9 / FS-1021: Payments & History - "No payment" rows, the All landing
// filter, the History routes and the sheet sort.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/company_module.dart';
import 'package:xpensedesk_flutter/models/payment_direction.dart';
import 'package:xpensedesk_flutter/models/payment_report_row.dart';
import 'package:xpensedesk_flutter/models/payment_status.dart';
import 'package:xpensedesk_flutter/models/payments_filter.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';
import 'package:xpensedesk_flutter/utils/payments_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/payments_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

PaymentReportRow _row(String id, {String? status, String? budget, int? number, String name = 'Dana'}) =>
    PaymentReportRow.fromJson({
      'expenseSheetId': id,
      'employeeName': name,
      'amount': 0,
      'paymentStatus': status,
      'sheetType': budget == null ? 'Monthly' : 'PettyCash',
      'budgetName': budget,
      'budgetNumber': number,
      'cycleLabel': null,
      'expenseCycleId': null,
    });

void main() {
  group('No payment rows', () {
    test('a null status is No payment: grey pill, never awaiting', () {
      final r = _row('a');
      expect(r.paymentStatus, isNull);
      expect(r.isNoPayment, isTrue);
      expect(r.isAwaiting, isFalse);
      expect(r.displayStatus, PaymentStatus.noPayment);
      expect(r.cycleLabel, '', reason: 'a budget with nothing owed has no cycle');
    });

    test('a pending row is not No payment', () {
      final r = _row('b', status: 'AwaitingPayment');
      expect(r.isNoPayment, isFalse);
      expect(r.displayStatus, PaymentStatus.awaitingPayment);
    });

    test('the money totals leave No payment rows out', () {
      final t = PaymentTotals.of([
        PaymentReportRow.fromJson({'expenseSheetId': 'x', 'amount': -40, 'paymentStatus': null}),
        PaymentReportRow.fromJson({'expenseSheetId': 'y', 'amount': 25, 'paymentStatus': 'AwaitingPayment'}),
      ]);
      expect(t.count, 1);
      expect(t.payAmount, 25);
      expect(t.collectAmount, 0);
    });

    test('money an employee gave back reads Returned for them, Charged for a manager', () {
      String text(bool holder, AppLocalizations l) => paymentStatusText(l, PaymentStatus.processed,
          direction: PaymentDirection.collect, forHolder: holder);
      expect(text(true, en), 'Returned');
      expect(text(true, he), 'הוחזר');
      expect(text(false, en), 'Charged');
    });

    test('No payment reads in both languages', () {
      expect(paymentStatusText(en, PaymentStatus.noPayment), 'No payment');
      expect(paymentStatusText(he, PaymentStatus.noPayment), 'ללא תשלום');
    });

    test('the sheet label names the budget, or the sheet type', () {
      expect(paymentSheetLabelText(en, _row('c', budget: 'Events', number: 1004)), 'Events #1004');
      expect(paymentSheetLabelText(en, _row('d')), paymentSheetTypeText(en, CompanyModuleKey.monthly));
    });
  });

  group('Filter', () {
    test('lands on every status and always asks for No payment sheets', () {
      expect(PaymentsFilter.defaults.status, isNull);
      expect(PaymentsFilter.defaults.toQueryParams(), {'includeNoPayment': 'true'});
    });

    test('the No payment filter sends status 0', () {
      final q = const PaymentsFilter(status: PaymentStatus.noPayment).toQueryParams();
      expect(q['paymentStatus'], '0');
    });

    test('the dashboard card still opens on Pending', () {
      final f = PaymentsFilter.defaults.copyWith(status: PaymentStatus.awaitingPayment);
      expect(f.toQueryParams()['paymentStatus'], '1');
    });
  });

  // The menu itself (menu_items.dart) needs dart:html - checked in manual QA.
  test('an employee History sheet lives under History', () {
    expect(AppRoutes.employeeHistory, '/employee/history');
    expect(AppRoutes.historySheetPath('x'), '/employee/history/sheet/x');
  });

  test('sorting by name falls back to the sheet - an employee History has one name', () {
    final rows = [
      _row('1', budget: 'Zeta', number: 1002),
      _row('2'),
      _row('3', budget: 'Alpha', number: 1001),
    ];
    final sorted = PaymentsSortUtils.sort(rows, PaymentsSortField.employee, ascending: true);
    expect(sorted.map((r) => r.expenseSheetId), ['2', '3', '1'],
        reason: 'Monthly first, then budgets by name');
  });
}
