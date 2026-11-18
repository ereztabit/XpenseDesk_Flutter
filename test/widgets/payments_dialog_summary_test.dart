// The Mark-as-processed / Edit dialog summary wraps on a phone instead of
// overflowing (owner QA 2026-11-18: "RIGHT OVERFLOWED BY 36 PIXELS").
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/widgets/payments/payments_dialog_summary.dart';

void main() {
  for (final locale in ['en', 'he']) {
    testWidgets('long pay / charge summary fits a phone dialog ($locale)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The content width of the dialog on a 375px phone.
        home: const Scaffold(
          body: SizedBox(
            width: 246,
            child: PaymentsDialogSummary(
              sheetCount: 12,
              amountText:
                  'To pay 11 · ₪12,307.24  |  To charge 1 · ₪1,060.00',
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  }
}
