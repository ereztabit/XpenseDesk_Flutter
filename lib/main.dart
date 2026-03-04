import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'generated/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'router.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/app_navigator.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Short-circuit: render a bare static page with zero backend involvement.
  if (Uri.base.path == '/ping') {
    runApp(const _PingApp());
    return;
  }

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
      onGenerateRoute: generateRoute,
    );
  }
}

/// Bare-bones app used only for /ping — no config, no providers, no backend.
class _PingApp extends StatelessWidget {
  const _PingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Hello, World!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

