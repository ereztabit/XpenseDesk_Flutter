// FS-1020 PC-8: what approving a budget settles, and in which cycle (D10/D11).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/budget.dart';
import 'package:xpensedesk_flutter/models/expense_cycle.dart';
import 'package:xpensedesk_flutter/models/payment_direction.dart';
import 'package:xpensedesk_flutter/utils/settlement_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

Budget _b(double amount, double spent) => Budget(
      budgetId: 'b1',
      number: 1001,
      name: 'Tour',
      holderUserId: 'u1',
      holderName: 'Dana Levi',
      holderEmail: 'dana@acme.test',
      statusId: 2,
      initialAmount: amount,
      budgetAmount: amount,
      spentAmount: spent,
      balance: amount - spent,
      endDate: DateTime(2026, 12, 31),
      currencyCode: 'ILS',
      createdAt: DateTime(2026, 11, 1),
    );

ExpenseCycle _c(String status, {String? label, String start = ''}) =>
    ExpenseCycle(
      expenseCycleId: status,
      cycleStartAt: start,
      cycleEndAt: '',
      cycleStatus: status,
      cycleLabel: label,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('he');
  });

  test('settlement = spent - budget amount, direction by sign', () {
    expect(budgetSettlementAmount(_b(1000, 1200)), 200);
    expect(budgetSettlementAmount(_b(1000, 700)), -300);
    expect(PaymentDirection.fromAmount(200), PaymentDirection.pay);
    expect(PaymentDirection.fromAmount(-300), PaymentDirection.collect);
    expect(PaymentDirection.fromAmount(0), isNull);
  });

  test('open cycle label: label, else derived from the start date', () {
    expect(
        openCycleLabel(
            [_c('Closed', label: '2026/10'), _c('Open', label: '2026/11')]),
        '2026/11');
    expect(
        openCycleLabel([_c('Open', start: '2026-03-01T00:00:00')]), '2026/03');
    expect(openCycleLabel([_c('Closed', label: '2026/10')]), isNull);
    expect(openCycleLabel(const []), isNull);
  });

  group('approval text', () {
    String text(AppLocalizations l10n, Budget b, String? cycle) =>
        budgetApprovalSettlementText(l10n, b, cycleLabel: cycle, locale: 'en');

    test('collect, with the cycle', () {
      final t = text(en, _b(1000, 800), '2026/11');
      expect(t, startsWith('To charge '));
      expect(t, contains('200'));
      expect(t, contains('from \u2068Dana Levi\u2069 - in the payments of November 2026'));
    });

    test('pay, without a known cycle', () {
      final t = text(en, _b(1000, 1050), null);
      expect(t, startsWith('To pay '));
      expect(t, endsWith('to \u2068Dana Levi\u2069'));
    });

    test('nothing to settle', () {
      expect(text(en, _b(1000, 1000), '2026/11'), en.settlementNothing);
    });

    test('Hebrew word order', () {
      final t = text(he, _b(1000, 800), '2026/11');
      expect(t, startsWith('לגבות '));
      expect(t, contains('מאת \u2068Dana Levi\u2069 - בתשלומי '));
    });
  });
}
