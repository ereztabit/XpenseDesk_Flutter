import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';

void main() {
  group('AppRoutes.isLoginLink', () {
    bool check(String url) => AppRoutes.isLoginLink(Uri.parse(url));

    test('a login link with a token is a login link', () {
      expect(check('https://app.xpensedesk.com/login?token=abc123'), isTrue);
      expect(check('http://localhost:5000/login?token=abc&lang=he'), isTrue);
    });

    test('/login without a usable token is not', () {
      expect(check('https://app.xpensedesk.com/login'), isFalse);
      expect(check('https://app.xpensedesk.com/login?token='), isFalse);
      expect(check('https://app.xpensedesk.com/login?other=1'), isFalse);
    });

    test('a token on any other route is not', () {
      expect(check('https://app.xpensedesk.com/?token=abc'), isFalse);
      expect(check('https://app.xpensedesk.com/onboarding?token=abc'), isFalse);
      expect(check('https://app.xpensedesk.com/login/extra?token=abc'), isFalse);
    });
  });
}
