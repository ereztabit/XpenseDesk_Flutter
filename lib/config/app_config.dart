import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Simple configuration loader
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

  String get apiBaseUrl => _config['api']['baseUrl'] as String;
}
