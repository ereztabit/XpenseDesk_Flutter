// FS-1026 round 4 - the filter dropdowns follow a UI language switch, and the
// scan review fields stack on a phone with the Correct value inputs full width.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_review_utils.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_company_dropdown.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_profile_dropdown.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_field_block.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_field_row.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_fields_form.dart';

Widget _app(Locale locale, Widget Function(AppLocalizations l10n) child) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Builder(builder: (context) => child(AppLocalizations.of(context)!))),
);

/// The dropdown field's own text (the EditableText inside the TextField).
String _fieldText(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText).first).controller.text;

Widget _filters(AppLocalizations l10n) => Column(
  children: [
    AiCompanyDropdown(companies: const [], selectedId: null, allLabel: l10n.adminAiAllCompanies, onSelected: (_) {}),
    AiProfileDropdown(profiles: const [], selectedId: null, allLabel: l10n.adminAiAllProfiles, onSelected: (_) {}),
  ],
);

void main() {
  testWidgets('switching EN -> HE redraws the "all" labels in Hebrew', (tester) async {
    final en = lookupAppLocalizations(const Locale('en'));
    final he = lookupAppLocalizations(const Locale('he'));
    expect(he.adminAiAllCompanies, isNot(en.adminAiAllCompanies));

    await tester.pumpWidget(_app(const Locale('en'), _filters));
    await tester.pumpAndSettle();
    final texts = tester.widgetList<EditableText>(find.byType(EditableText)).map((e) => e.controller.text);
    expect(texts, [en.adminAiAllCompanies, en.adminAiAllProfiles]);
    expect(_fieldText(tester), en.adminAiAllCompanies);

    await tester.pumpWidget(_app(const Locale('he'), _filters));
    await tester.pumpAndSettle();
    final heTexts = tester.widgetList<EditableText>(find.byType(EditableText)).map((e) => e.controller.text);
    expect(heTexts, [he.adminAiAllCompanies, he.adminAiAllProfiles]);
  });

  testWidgets('375px: each field is a stacked block, inputs full width, no sideways scroll', (tester) async {
    tester.view.physicalSize = const Size(375, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final review = AdminAiScanReview(
      expenseId: 'e1',
      companyId: 'c1',
      companyName: 'Harbor',
      isClosed: false,
      isForeign: false,
      modelResults: const [],
      expense: AdminAiScanValues(merchant: 'Cafe', date: '2026-11-12', amount: 80, currency: 'ILS', receiptNumber: '7'),
    );

    await tester.pumpWidget(
      _app(
        const Locale('en'),
        (_) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AiScanFieldsForm(review: review, busy: false, onSave: (_) {}, onVerify: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AiScanFieldRow), findsNothing);
    expect(find.byType(AiScanFieldBlock), findsNWidgets(AdminAiField.values.length));
    expect(
      find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal),
      findsNothing,
    );
    // Nothing inside the field blocks overflows. The card title (shared
    // ProfileSectionCard) is drawn in the test font - every glyph a full square
    // - and runs past 375px here only; that one report is consumed.
    final blockFlexes = find.descendant(
      of: find.byType(AiScanFieldBlock),
      matching: find.byWidgetPredicate((w) => w is Flex),
    );
    expect(blockFlexes, findsWidgets);
    for (final e in blockFlexes.evaluate()) {
      expect(e.renderObject!.toStringShallow(), isNot(contains('OVERFLOWING')));
    }
    tester.takeException();

    // Every Correct value input (VAT has none) sits on screen, full width.
    final inputs = find.byType(TextFormField);
    expect(inputs, findsNWidgets(AdminAiField.values.length - 1));
    for (final e in inputs.evaluate()) {
      final box = e.renderObject! as RenderBox;
      final left = box.localToGlobal(Offset.zero).dx;
      expect(left, greaterThanOrEqualTo(0));
      expect(left + box.size.width, lessThanOrEqualTo(375));
      expect(box.size.width, greaterThan(280));
      expect(box.size.height, greaterThanOrEqualTo(40));
    }
  });
}
