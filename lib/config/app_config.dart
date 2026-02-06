import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class AppConfig {
  static AppConfig? _instance;
  late Map<dynamic, dynamic> _config;
  
  // Use --dart-define=ENV=prod to override (dev, staging, prod)
  static const envOverride = String.fromEnvironment('ENV', defaultValue: 'dev');

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
    final yamlString = await rootBundle.loadString('assets/config/app_config_$envOverride.yaml');
    _config = loadYaml(yamlString);
  }

  String get apiBaseUrl => _config['api']['baseUrl'] as String;
  String get appName => _config['app']['name'] as String;
  String get appVersion => _config['app']['version'] as String;
  String get environment => _config['app']['environment'] as String;
}
