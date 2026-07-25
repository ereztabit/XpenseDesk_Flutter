import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Simple configuration loader.
///
/// Dev mode  → backend runs on the same machine as the browser.
///             [apiBaseUrl] is derived from [Uri.base.host] + [backendPort],
///             so the same build works from any host (127.0.0.1, 10.x.x.x, etc.).
///             Config keys: isBackendOnSameMachine: true, backendPort, backendScheme.
///
/// Prod mode → backend is a fixed URL.
///             Config keys: isBackendOnSameMachine: false, baseUrl.
class AppConfig {
  static AppConfig? _instance;
  late Map<dynamic, dynamic> _config;

  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// True when running the dev build. Gates debug-only UI (dev tools must never
  /// render in production). Safe to read before [getInstance] — it is a
  /// compile-time constant and does not touch the loaded YAML.
  static bool get isDev => environment == 'dev';

  AppConfig._();

  static Future<AppConfig> getInstance() async {
    if (_instance == null) {
      _instance = AppConfig._();
      await _instance!._loadConfig();
    }
    return _instance!;
  }

  static AppConfig get instance => _instance!;

  Future<void> _loadConfig() async {
    final yamlString = await rootBundle.loadString('assets/config/app_config_$environment.yaml');
    _config = loadYaml(yamlString);
  }

  /// Returns the API base URL.
  ///
  /// When [isBackendOnSameMachine] is true the URL is built at runtime from
  /// the browser's current hostname so that the same build works whether
  /// you're hitting 127.0.0.1, 10.100.x.x, or any other host.
  String get apiBaseUrl {
    final api = _config['api'] as Map;
    final sameMachine = api['isBackendOnSameMachine'] as bool? ?? false;

    if (sameMachine) {
      final scheme = api['backendScheme'] as String? ?? 'https';
      final port   = api['backendPort']   as int?    ?? 7223;
      final host   = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return '$scheme://$host:$port';
    }

    return api['baseUrl'] as String;
  }

  String get tranzilaTerminal {
    final payment = _config['payment'] as Map;
    return payment['tranzilaTerminal'] as String;
  }

  bool get tranzilaUse3ds {
    final payment = _config['payment'] as Map;
    return payment['use3ds'] as bool? ?? false;
  }

  /// Length of the free trial in days, used for the plan-selection copy.
  /// The authoritative trial end date still comes from the backend.
  int get trialDays {
    final trial = _config['trial'] as Map?;
    return trial?['trialDays'] as int? ?? 14;
  }

  /// Feature flag: show the "Sign in with Microsoft" button and process the
  /// Microsoft redirect on return. Defaults to false (safe/off) when absent.
  bool get enableMicrosoftLogin {
    final features = _config['features'] as Map?;
    return features?['enableMicrosoftLogin'] as bool? ?? false;
  }

  /// Feature flag: emit Microsoft-login diagnostic logs (JS glue + bootstrap)
  /// to the browser console. Intended for debugging Microsoft login in
  /// production; defaults to false (quiet) when absent.
  bool get enableMicrosoftLoginLogs {
    final features = _config['features'] as Map?;
    return features?['enableMicrosoftLoginLogs'] as bool? ?? false;
  }

  /// Feature flag: show "Subscribe with Microsoft" on onboarding step 1 and
  /// consume its redirect return on /onboarding (no-OTP SSO onboarding).
  /// Defaults to false (safe/off) when absent.
  bool get enableMicrosoftOnboarding {
    final features = _config['features'] as Map?;
    return features?['enableMicrosoftOnboarding'] as bool? ?? false;
  }
}
