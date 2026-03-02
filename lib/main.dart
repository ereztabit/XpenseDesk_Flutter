import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'generated/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/users_screen.dart';
import 'screens/spend_history_screen.dart';
import 'screens/company_config_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/app_navigator.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await AppConfig.getInstance();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire up the global 401 handler: clear in-memory session state,
    // clear the stored token, then hard-navigate to the login page.
    ApiService.onUnauthorized = () {
      ref.read(userInfoProvider.notifier).handleUnauthorized();
      ref.read(authServiceProvider).clearSessionToken();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'XpenseDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Localization
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('he'),
      ],
      
      // Routes
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        
        // Handle /login route with token query parameter
        if (uri.path == '/login') {
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoginCallbackScreen(token: token),
          );
        }
        
        // Handle other routes
        switch (uri.path) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginScreen(),
            );
          case '/onboarding':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const OnboardingScreen(),
            );
          case '/dashboard':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const DashboardScreen(),
            );
          case '/manager/profile':
          case '/employee/profile':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const ProfileScreen(),
            );
          case '/manager/users':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const UsersScreen(),
            );
          case '/manager/history':
          case '/employee/history':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const SpendHistoryScreen(),
            );
          case '/manager/company-config':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const CompanyConfigScreen(),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginScreen(),
            );
        }
      },
    );
  }
}

