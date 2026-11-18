// FS-1019 — the Currencies table renders one row per currency with its status
// chip and rate, in both languages.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/admin_currency_status.dart';
import 'package:xpensedesk_flutter/widgets/admin/admin_currencies_table.dart';

Widget _host(Widget child, {String locale = 'en'}) => MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SizedBox(width: 1200, height: 600, child: child)),
    );

AdminCurrencyRow _row(String code, String status, {double? rate, int? unit, int count = 10}) =>
    AdminCurrencyRow.fromJson({
      'currencyCode': code,
      'currencyName': '$code name',
      'currencySymbol': '\$',
      'status': status,
      'lastRateDate': count == 0 ? null : '2026-11-17',
      'lastRate': rate,
      'lastUnitMult': unit,
      'rateCount': count,
    });

void main() {
  setUpAll(() => initializeDateFormatting('he'));

  testWidgets('one row per currency with status and rate', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AdminCurrenciesTable(currencies: [
      _row('USD', 'Ok', rate: 3.246, unit: 0),
      _row('JPY', 'Behind', rate: 2.04, unit: 2),
      _row('CHF', 'NoData', count: 0),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('USD'), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);
    expect(find.text('3.246'), findsOneWidget);
    expect(find.text('Behind'), findsOneWidget);
    expect(find.text('2.04 per 100'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('empty list shows the empty message', (tester) async {
    await tester.pumpWidget(_host(const AdminCurrenciesTable(currencies: [])));
    await tester.pumpAndSettle();
    expect(find.text('No rates stored yet'), findsOneWidget);
  });

  testWidgets('Hebrew labels', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      AdminCurrenciesTable(currencies: [_row('USD', 'Failed', rate: 3.2, unit: 0)]),
      locale: 'he',
    ));
    await tester.pumpAndSettle();
    expect(find.text('נכשל'), findsOneWidget);
  });
}
