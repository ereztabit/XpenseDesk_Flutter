// FS-1020 PC-8 F3: the sheet-type filter on the payments report.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/company_module.dart';
import 'package:xpensedesk_flutter/models/payments_filter.dart';

void main() {
  const budgets = PaymentsFilter(sheetType: CompanyModuleKey.pettyCash);

  test('sends sheetType only when set', () {
    expect(PaymentsFilter.defaults.toQueryParams().containsKey('sheetType'),
        isFalse);
    expect(budgets.toQueryParams()['sheetType'], 'PettyCash');
  });

  test('counts as an active filter and takes part in equality', () {
    expect(budgets.activeCount, 1);
    expect(budgets == const PaymentsFilter(), isFalse);
    expect(
        budgets == const PaymentsFilter(sheetType: CompanyModuleKey.pettyCash),
        isTrue);
  });

  test('copyWith keeps, sets and clears it', () {
    expect(
        budgets.copyWith(cycleId: 'c').sheetType, CompanyModuleKey.pettyCash);
    expect(budgets.copyWith(sheetType: null).sheetType, isNull);
    expect(
        PaymentsFilter.defaults
            .copyWith(sheetType: CompanyModuleKey.monthly)
            .toQueryParams()['sheetType'],
        'Monthly');
  });
}
