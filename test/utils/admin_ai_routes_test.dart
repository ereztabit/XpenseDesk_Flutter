// FS-1026 Receipt AI routes: tab, profile number and expense id live in the path.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';

void main() {
  const id = '3f2b6c1e-9a4d-4b7e-8c21-5d6f7a8b9c0d';

  test('the module root and its tabs', () {
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai'), (tab: null, profileId: null, expenseId: null));
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/'), (tab: null, profileId: null, expenseId: null));
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/usage')?.tab, 'usage');
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/companies')?.tab, 'companies');
  });

  test('one profile by its number', () {
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/profiles/2')?.profileId, 2);
    expect(AppRoutes.parseAdminReceiptAiPath(AppRoutes.adminAiProfile(17))?.profileId, 17);
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/profiles/0'), isNull);
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/profiles/abc'), isNull);
  });

  test('one scan by its expense id', () {
    expect(AppRoutes.parseAdminReceiptAiPath(AppRoutes.adminAiScan(id))?.expenseId, id);
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/usage/scans/not-a-guid'), isNull);
  });

  test('other admin paths are not Receipt AI', () {
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/companies'), isNull);
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-aix'), isNull);
    expect(AppRoutes.parseAdminReceiptAiPath('/admin/receipt-ai/profiles/2/extra'), isNull);
  });
}
