// FS-1026 - after Save to expense (or Verified) the review reloads; the reloaded
// expense becomes the form's new baseline: nothing highlighted, Save disabled,
// Verified enabled.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_fields_form.dart';
import 'package:xpensedesk_flutter/widgets/app_button.dart';

AdminAiScanReview _review(String merchant, String receiptNo) => AdminAiScanReview(
  expenseId: 'e1',
  companyId: 'c1',
  companyName: 'Harbor',
  isClosed: false,
  isForeign: false,
  modelResults: const [],
  expense: AdminAiScanValues(
    merchant: merchant,
    date: '2026-11-12',
    amount: 80,
    currency: 'ILS',
    receiptNumber: receiptNo,
  ),
);

Widget _host(AdminAiScanReview review) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(
        width: 900,
        child: AiScanFieldsForm(
          key: const ValueKey('e1'),
          review: review,
          busy: false,
          onSave: (_) {},
          onVerify: () {},
        ),
      ),
    ),
  ),
);

AppButton _button(WidgetTester tester, String label) => tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  testWidgets('a reloaded expense resets the form baseline', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_review('Demo Print House', '100')));
    await tester.pumpAndSettle();
    expect(_button(tester, 'Save to expense').onPressed, isNull);
    expect(_button(tester, 'Verified').onPressed, isNotNull);

    await tester.enterText(find.byKey(const ValueKey('correct-merchant-0')), 'Demo Print House 2');
    await tester.enterText(find.byKey(const ValueKey('correct-receiptNumber-0')), '101');
    await tester.pump();
    expect(_button(tester, 'Save to expense (2)').onPressed, isNotNull);
    expect(_button(tester, 'Verified').onPressed, isNull);

    // The save succeeded and the review reloaded with the saved values.
    await tester.pumpWidget(_host(_review('Demo Print House 2', '101')));
    await tester.pumpAndSettle();

    expect(find.text('Save to expense (2)'), findsNothing);
    expect(_button(tester, 'Save to expense').onPressed, isNull);
    expect(_button(tester, 'Verified').onPressed, isNotNull);
    final merchant = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const ValueKey('correct-merchant-1')), matching: find.byType(EditableText)),
    );
    expect(merchant.controller.text, 'Demo Print House 2');
  });
}
