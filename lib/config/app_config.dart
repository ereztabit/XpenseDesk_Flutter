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
}
