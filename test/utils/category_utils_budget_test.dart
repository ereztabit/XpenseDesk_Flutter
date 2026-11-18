import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/company_category.dart';
import 'package:xpensedesk_flutter/models/company_module.dart';
import 'package:xpensedesk_flutter/utils/category_utils.dart';

// FS-1012 S2a: the expense-form category helpers take the sheet's module;
// Monthly stays the default, so every existing caller is unchanged.
CompanyCategory _c(int id, CompanyModuleKey module, String nameEn, {bool active = true}) =>
    CompanyCategory(
      categoryId: id,
      module: module,
      nameEn: nameEn,
      nameHe: null,
      taxKey: null,
      isActive: active,
      isSystem: false,
      isFallback: false,
      isUsed: false,
    );

void main() {
  final categories = [
    _c(10, CompanyModuleKey.monthly, 'Supplies'),
    _c(11, CompanyModuleKey.monthly, 'Old', active: false),
    _c(20, CompanyModuleKey.pettyCash, 'Cleaning'),
    _c(21, CompanyModuleKey.pettyCash, 'Retired', active: false),
  ];

  test('Monthly is the default picker list', () {
    expect(expenseCategoryChoices(categories, 'en').map((c) => c.categoryId), [10]);
  });

  test('a budget picks active Budgets categories, plus its kept one', () {
    expect(
      expenseCategoryChoices(categories, 'en', module: CompanyModuleKey.pettyCash)
          .map((c) => c.categoryId),
      [20],
    );
    expect(
      expenseCategoryChoices(categories, 'en',
              module: CompanyModuleKey.pettyCash, keepCategoryId: 21)
          .map((c) => c.categoryId)
          .toSet(),
      {20, 21},
    );
  });

  test('a scanned id maps within the module only', () {
    expect(resolveScannedCategoryId(categories, 20, module: CompanyModuleKey.pettyCash), 20);
    expect(resolveScannedCategoryId(categories, 10, module: CompanyModuleKey.pettyCash), isNull);
    expect(resolveScannedCategoryId(categories, 3, module: CompanyModuleKey.pettyCash), isNull,
        reason: 'legacy 1-6 ids are Monthly');
  });

  test('moduleOfCategory tells a budget line from a Monthly one', () {
    expect(moduleOfCategory(categories, 20), CompanyModuleKey.pettyCash);
    expect(moduleOfCategory(categories, 10), CompanyModuleKey.monthly);
    expect(moduleOfCategory(categories, 999), CompanyModuleKey.monthly);
  });
}
