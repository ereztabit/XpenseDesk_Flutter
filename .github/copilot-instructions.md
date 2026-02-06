# GitHub Copilot Instructions

## Background

I am a senior developer with 20+ years of coding experience, specializing in .NET web development with strong vanilla JavaScript expertise. I am learning Flutter to expand my mobile development capabilities.

## Project Context

This Flutter application is **XpenseDesk** - an AI-powered expense approval tool for small businesses. The complete product specification and MVP scope are defined in:

- [AI Expense Approval MVP North Star](../docs/ai_expense_approval_mvp_north_star.md) - Complete product vision, feature set, user journeys, and business rules
- [MVP Screen Map](../docs/mvp_screen_map.md) - Screen definitions and user flows

**These documents are the source of truth for what we're building.** All implementation decisions should align with the MVP definition and user journeys described in these specifications.

## Teaching Approach

When providing assistance:

1. **Explain the Why**: Focus on architectural decisions, performance implications, and Flutter-specific patterns
2. **Skip the Basics**: Assume I understand general programming concepts (OOP, async, dependency injection, etc.)
3. **Professional Level**: Explain Flutter idioms and how they compare to .NET/JavaScript patterns when relevant
4. **Code Examples**: Provide production-quality code with minimal comments - only explain Flutter-specific nuances
5. **Trade-offs**: Discuss performance, maintainability, and scalability considerations like you would with a senior engineer

## Communication Style

- Talk to me like a senior engineer, not a student
- Skip explaining general programming concepts (async/await, dependency management, patterns, etc.)
- Focus on Flutter-specific concepts and how they differ from .NET/JavaScript paradigms
- Use technical terminology without over-explaining
- When relevant, draw parallels to .NET (LINQ → Dart collections, async/await patterns, MVVM, etc.) and vanilla JavaScript
- DO NOT use React examples or comparisons - I don't know React
- Provide concise, direct answers - I can dive deeper if needed

---

## Project Architecture Standards

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # Configuration
│   └── app_config.dart         # Environment-specific config loader
├── models/                      # Data models / DTOs
│   ├── weather_forecast.dart
│   └── calculator.dart
├── services/                    # Business logic / API clients
│   └── weather_service.dart
├── providers/                   # Riverpod providers (state management)
│   ├── weather_provider.dart
│   └── calculator_provider.dart
├── screens/                     # Full-page screens
│   ├── home_page.dart
│   └── weather_screen.dart
├── widgets/                     # Reusable UI components
│   ├── audit_widget.dart
│   └── language_picker.dart
├── theme/                       # UI theming
│   └── app_theme.dart
└── l10n/                        # Localization files
    ├── app_en.arb
    └── app_he.arb

assets/
└── config/                      # Environment config files
    ├── app_config.yaml
    ├── app_config_dev.yaml
    └── app_config_prod.yaml
```

**Principles:**
- **Separation of concerns**: Models, services, UI, state are isolated
- **Testability**: Services and providers are easily mockable
- **One widget per file** for screens/complex widgets

---

### Configuration Management

**Environment-Specific Configuration Pattern:**

```dart
// lib/config/app_config.dart
class AppConfig {
  static AppConfig? _instance;
  late Map<dynamic, dynamic> _config;
  
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');

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
```

**Config file:**
```yaml
# assets/config/app_config_dev.yaml
api:
  baseUrl: https://localhost:7223

app:
  name: MyApp Dev
  environment: development
```

**Initialization:**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.getInstance(); // Initialize before runApp
  runApp(const MyApp());
}
```

**Key Points:**
- **Selection**: `--dart-define=ENV=prod` at build/run time
- **Access**: `AppConfig.instance.apiBaseUrl` (singleton pattern)
- YAML files bundled in assets, loaded at runtime
- Must initialize async before first use

---

### Service Layer Pattern

```dart
// lib/services/weather_service.dart
class WeatherService {
  final String baseUrl;

  WeatherService({String? baseUrl}) 
      : baseUrl = baseUrl ?? AppConfig.instance.apiBaseUrl;

  Future<List<WeatherForecast>> getWeatherForecast() async {
    final uri = Uri.parse('$baseUrl/WeatherForecast/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => WeatherForecast.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load: ${response.statusCode}');
    }
  }
}
```

**Best Practices:**
- Constructor injection for dependencies (testability)
- Return domain models, not raw JSON
- Throw typed exceptions
- Default to config values: `baseUrl ?? AppConfig.instance.apiBaseUrl`

---

### State Management (Riverpod)

```dart
// lib/providers/weather_provider.dart
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherForecastProvider = FutureProvider<List<WeatherForecast>>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getWeatherForecast();
});
```

**Usage in widgets:**
```dart
class WeatherScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherForecastProvider);

    return weatherAsync.when(
      data: (forecasts) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(),
    );
  }
}
```

**Provider Types:**
- **Provider**: Singletons, services (like DI container)
- **StateProvider**: Simple mutable state (counter, toggles)
- **FutureProvider**: Async data loading (auto loading/error states)
- **StateNotifierProvider**: Complex mutable state
- **StreamProvider**: Real-time data streams

**Key Rule:** Keep business logic in providers/services, not widgets

---

### Models & DTOs

**Pattern: Immutable data classes with JSON serialization**

```dart
class WeatherForecast {
  final DateTime date;
  final int temperatureC;
  final String summary;

  const WeatherForecast({
    required this.date,
    required this.temperatureC,
    required this.summary,
  });

  int get temperatureF => 32 + (temperatureC * 9 ~/ 5);

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.parse(json['date']),
      temperatureC: json['temperatureC'],
      summary: json['summary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperatureC': temperatureC,
      'summary': summary,
    };
  }
}
```

**Best Practices:**
- Immutable (`const` constructors, `final` fields)
- `factory fromJson()` for deserialization
- `toJson()` for serialization
- Computed properties as getters

---

### Development Workflow

**VS Code Launch Configurations:**
```json
// .vscode/launch.json
{
  "configurations": [
    {
      "name": "Flutter Dev (Chrome)",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["-d", "chrome", "--web-port=8080", "--dart-define=ENV=dev"]
    },
    {
      "name": "Flutter Prod (Chrome)",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["-d", "chrome", "--web-port=8080", "--dart-define=ENV=prod"]
    }
  ]
}
```

**Running:**
- **F5**: Debug with selected launch config
- **Ctrl+Shift+B**: Run default task
- **Hot Reload**: `r` in terminal (preserves state)
- **Hot Restart**: `R` in terminal (resets state)

**When to use what:**
- `.dart` edits → Hot reload (r)
- ARB, pubspec.yaml, assets → `pub get` + Hot restart (R)
- Native code changes → Full rebuild

---

### Best Practices

**Code Organization:**
- **Const constructors** everywhere possible (performance)
- **Named parameters** for widget constructors
- **Extract widgets** when build methods get large (>100 lines)

**State Management:**
- **Minimize setState()**: Use Riverpod for anything shared
- **Immutable state**: Always create new objects, never mutate
- **Provider per concern**: Don't create god providers

**Performance:**
- **const widgets**: Prevent unnecessary rebuilds
- **ListView.builder**: For dynamic/large lists (lazy loading)
- **Avoid deep widget trees**: Extract reusable components

**API Integration:**
- **Timeout handling**: Set timeouts on HTTP requests
- **Error types**: Create custom exception classes
- **Retry logic**: For transient failures

---

## Quick .NET → Flutter Reference

| .NET | Flutter/Dart |
|------|--------------|
| IServiceProvider | Provider/Riverpod |
| Task\<T\> | Future\<T\> |
| INotifyPropertyChanged | StateNotifier |
| HttpClient | http package |
| System.Text.Json | dart:convert + fromJson/toJson |
| IAsyncEnumerable\<T\> | Stream\<T\> |
| appsettings.json | YAML config files |
| Dependency Injection | Provider pattern |
| LINQ | Iterable methods (map, where, etc.) |

**Key Differences:**
- `_` prefix = private to file (not class)
- No interfaces, use abstract classes
- `late` for lazy init, `const` for compile-time constants
- Mixins with `with` keyword
- No null-coalescing assignment operator (use `??=`)

---

## Flutter Focus Areas

Help me learn and implement:

- **Flutter Basics**: Widgets, state management, widget tree, build methods
- **UI/UX**: Material Design, Cupertino widgets, custom widgets, responsive layouts
- **State Management**: setState, Provider, Riverpod, BLoC patterns
- **Navigation**: Routes, named routes, navigation patterns
- **Forms & Validation**: Form handling, input validation, user input
- **API Integration**: HTTP requests, REST APIs, data fetching, JSON parsing
- **Async Programming**: Futures, async/await, streams
- **Local Storage**: SharedPreferences, SQLite, Hive
- **Architecture**: Clean architecture, separation of concerns, project structure
- **Testing**: Widget tests, unit tests, integration tests
- **Performance**: Build optimization, lazy loading, performance best practices
