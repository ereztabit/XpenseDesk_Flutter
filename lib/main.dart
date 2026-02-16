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
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await AppConfig.getInstance();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
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
            builder: (context) => LoginCallbackScreen(token: token),
          );
        }
        
        // Handle other routes
        switch (uri.path) {
          case '/':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => const DashboardScreen());
          case '/manager/profile':
          case '/employee/profile':
            return MaterialPageRoute(builder: (context) => const ProfileScreen());
          case '/manager/users':
            return MaterialPageRoute(builder: (context) => const UsersScreen());
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}

