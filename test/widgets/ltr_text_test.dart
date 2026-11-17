// Emails keep their real character order on Hebrew (RTL) screens, while their
// alignment still follows the page: `info@x.com_` must not render as
// `_info@x.com`.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/widgets/ltr_text.dart';
import 'package:xpensedesk_flutter/widgets/onboarding/microsoft_identity_card.dart';

const _email = 'info@bambayadigital.com_';

Widget _host(Widget child, {String locale = 'he'}) => MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Text _emailText(WidgetTester tester) =>
    tester.widget<Text>(find.text(_email));

void main() {
  testWidgets('RTL page: laid out LTR, start-aligned to the right',
      (tester) async {
    await tester.pumpWidget(_host(const LtrText(_email)));
    final text = _emailText(tester);
    expect(text.textDirection, TextDirection.ltr);
    expect(text.textAlign, TextAlign.right);
  });

  testWidgets('LTR page: start-aligned to the left', (tester) async {
    await tester.pumpWidget(_host(const LtrText(_email), locale: 'en'));
    expect(_emailText(tester).textAlign, TextAlign.left);
  });

  testWidgets('end and center keep their meaning against the page',
      (tester) async {
    await tester
        .pumpWidget(_host(const LtrText(_email, textAlign: TextAlign.end)));
    expect(_emailText(tester).textAlign, TextAlign.left);

    await tester.pumpWidget(
        _host(const LtrText(_email, textAlign: TextAlign.center)));
    expect(_emailText(tester).textAlign, TextAlign.center);
  });

  testWidgets('selectable variant is also LTR', (tester) async {
    await tester
        .pumpWidget(_host(const LtrText(_email, selectable: true)));
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(text.textDirection, TextDirection.ltr);
    expect(text.textAlign, TextAlign.right);
  });

  // Not reachable in manual QA without a real Microsoft sign-in.
  testWidgets('onboarding Microsoft identity card shows the email LTR',
      (tester) async {
    await tester.pumpWidget(_host(MicrosoftIdentityCard(
      fullName: 'Admin User',
      email: _email,
      onUseDifferentAccount: () {},
    )));
    expect(_emailText(tester).textDirection, TextDirection.ltr);
  });
}
