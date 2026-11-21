// FS-1026 - the ReceiptLab import check renders as a checklist, in both languages.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/admin_ai_import_check.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_import_report.dart';

Widget _host(Widget child, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SizedBox(width: 520, child: child)),
);

AdminAiImportCheck _check({bool today = true, List<String> missing = const [], bool replaces = false}) =>
    AdminAiImportCheck.fromJson({
      'canImport': today && missing.isEmpty,
      'hasSystemPrompt': true,
      'hasUserPrompt': true,
      'hasTodayToken': today,
      'mistralFieldsInFile': ['date'],
      'unknownFields': <String>[],
      'fieldsMissingFromPrompt': missing,
      'comparedWith': 'published',
      'comparedVersionNumber': 3,
      'gptChanged': true,
      'mistralFieldsChanged': ['date'],
      'replacesDraft': replaces,
    });

void main() {
  testWidgets('a good file reads as all found, with its changes', (tester) async {
    await tester.pumpWidget(_host(AiImportReport(check: _check())));
    await tester.pumpAndSettle();

    expect(find.text('Date placeholder'), findsOneWidget);
    expect(find.text('found'), findsNWidgets(3));
    expect(find.text('Changes from the current version (Published v3)'), findsOneWidget);
    expect(find.text('GPT prompt, date'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('This replaces the current draft.'), findsNothing);
  });

  testWidgets('problems are flagged, and replacing a draft is said', (tester) async {
    await tester.pumpWidget(_host(AiImportReport(check: _check(today: false, missing: ['amount'], replaces: true))));
    await tester.pumpAndSettle();

    expect(find.text('missing'), findsOneWidget);
    expect(find.text('amount'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    expect(find.text('This replaces the current draft.'), findsOneWidget);
  });

  testWidgets('renders in Hebrew without overflow', (tester) async {
    await tester.pumpWidget(_host(AiImportReport(check: _check(replaces: true)), locale: 'he'));
    await tester.pumpAndSettle();

    expect(find.text('מציין מקום לתאריך'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
