# CLAUDE.md — XpenseDesk Flutter

## Background

I am a senior developer with 20+ years of coding experience, specializing in .NET web development with strong vanilla JavaScript expertise. I am learning Flutter to expand my mobile development capabilities.

## Project Context

This Flutter application is **XpenseDesk** — an AI-powered expense approval tool for small businesses. The complete product specification and MVP scope are defined in:

- [AI Expense Approval MVP North Star](docs/ai_expense_approval_mvp_north_star.md) — Complete product vision, feature set, user journeys, and business rules
- [MVP Screen Map](docs/mvp_screen_map.md) — Screen definitions and user flows

**These documents are the source of truth for what we're building.** All implementation decisions should align with the MVP definition and user journeys described in these specifications.

## How to Work With Me

- Talk to me like a senior engineer, not a student
- Skip explaining general programming concepts (async/await, dependency management, patterns, etc.)
- Focus on Flutter-specific concepts and how they differ from .NET/JavaScript paradigms
- Use technical terminology without over-explaining
- When relevant, draw parallels to .NET (LINQ → Dart collections, async/await patterns, MVVM, etc.) and vanilla JavaScript
- **DO NOT use React examples or comparisons** — I don't know React
- Provide concise, direct answers — I can dive deeper if needed
- Production-quality code with minimal comments — only explain Flutter-specific nuances
- Discuss trade-offs (performance, maintainability, scalability) like you would with a senior engineer

---

## Project Architecture Standards

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # Configuration
│   └── app_config.dart         # Environment-specific config loader
├── models/                      # Data models / DTOs
├── services/                    # Business logic / API clients
├── providers/                   # Riverpod providers (state management)
├── screens/                     # Full-page screens
├── widgets/                     # Reusable UI components
├── utils/                       # Utility extensions and helpers
│   └── responsive_utils.dart   # Responsive breakpoint utilities
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

docs/                            # Guides and dev implementation notes
    ├── ai_expense_approval_mvp_north_star.md   # Product vision & MVP scope (source of truth)
    ├── mvp_screen_map.md                        # Screen definitions and user flows (source of truth)
    ├── authentication_client_guide.md
    ├── client-onboarding-company-api-guide.md
    ├── employee-expenses-implementation-plan.md
    ├── Exmployee-expenses-design.md
    ├── expense-api-guide.md
    ├── login.md
    ├── menu_system.md
    ├── onboarding-implementation-plan.md
    ├── user_profile_screen.md
    ├── users_api_documentation.md
    ├── users_management_ux.md
    ├── users_managment_gotodev.md
    ├── current-work.md                          # Active work + backlog TODOs
    └── README.md
```

**Principles:**
- Separation of concerns: Models, services, UI, state are isolated
- Testability: Services and providers are easily mockable
- One widget per file for screens/complex widgets

---

### Configuration Management

**Environment selection:** `--dart-define=ENV=prod` at build/run time
**Access:** `AppConfig.instance.apiBaseUrl` (singleton pattern)
YAML files bundled in assets, loaded at runtime. Must initialize async before first use.

---

### Service Layer Pattern

- Constructor injection for dependencies (testability)
- Return domain models, not raw JSON
- Throw typed exceptions
- Default to config values: `baseUrl ?? AppConfig.instance.apiBaseUrl`

---

### State Management (Riverpod)

**Provider Types:**
- `Provider` — Singletons, services (like DI container)
- `StateProvider` — Simple mutable state (counter, toggles)
- `FutureProvider` — Async data loading (auto loading/error states)
- `StateNotifierProvider` — Complex mutable state
- `StreamProvider` — Real-time data streams

**Key Rule:** Keep business logic in providers/services, not widgets.

---

### Models & DTOs

- Immutable (`const` constructors, `final` fields)
- `factory fromJson()` for deserialization
- `toJson()` for serialization
- Computed properties as getters

---

### Best Practices

**Code Organization:**
- `const` constructors everywhere possible (performance)
- Named parameters for widget constructors
- Extract widgets when build methods exceed ~100 lines

**State Management:**
- Minimize `setState()`: Use Riverpod for anything shared
- Immutable state: Always create new objects, never mutate
- Provider per concern: Don't create god providers

**Performance:**
- `const` widgets: Prevent unnecessary rebuilds
- `ListView.builder` for dynamic/large lists (lazy loading)
- Avoid deep widget trees: Extract reusable components

**API Integration:**
- Timeout handling: Set timeouts on HTTP requests
- Error types: Create custom exception classes
- Retry logic for transient failures

---

## Responsive Design Utilities

**CRITICAL: Never use `MediaQuery.of(context).size.width` directly.**
Always use the centralized responsive extension from `lib/utils/responsive_utils.dart`:

```dart
import '../utils/responsive_utils.dart';

if (context.isNarrow) { /* < 600px — stacked layouts */ }
if (context.isMobile) { /* < 768px — reduced padding */  }
```

**Available utilities:**
- `context.screenWidth` — Current screen width in pixels
- `context.isNarrow` — True if < 600px
- `context.isMobile` — True if < 768px
- `context.isWide` — True if >= 600px
- `context.isDesktop` — True if >= 768px

**Breakpoints:** 600px (narrow / stacked layouts), 768px (mobile optimizations)

---

## File Organization Rules

- Files with only data classes, utilities, or business logic → `lib/models/` or `lib/services/`
- Files with UI components extending Widget → `lib/widgets/`
- Group related widgets in subfolders: `lib/widgets/feature-name/`
- Shared/generic widgets stay at `lib/widgets/` root level
- One primary widget per file

---

## Naming Best Practices

**Widget naming:** Include platform context for platform-specific widgets
- Bad: `AvatarMenu` (ambiguous)
- Good: `DesktopMenu`, `MobileMenuSheet`

**File naming:** File names must match the primary class name in snake_case
- `DesktopMenu` class → `desktop_menu.dart`

---

## Flutter Modern Patterns

### Deprecated Methods to Avoid

- **DO NOT use `Color.withOpacity()`** — deprecated. Use `Color.withAlpha()` (0–255 range) instead.

**Opacity → Alpha conversion:**
- 10% → `withAlpha(25)`, 20% → `withAlpha(51)`, 40% → `withAlpha(102)`
- 60% → `withAlpha(153)`, 80% → `withAlpha(204)`
- Formula: `(opacity% * 2.55).round()`

### Dropdown Widgets

Use `DropdownMenu` (Material 3). **Do not use `DropdownButtonFormField`** (deprecated).
Key differences: `initialSelection`, `dropdownMenuEntries`, `onSelected`, `inputDecorationTheme`, `expandedInsets: EdgeInsets.zero`.

---

## API Patterns & Best Practices

### Reusable Validation Helpers

Extract repeated validation patterns into private helper methods (e.g., `_validateResponse`, `_validateSessionToken`). Don't repeat validation logic across service methods.

### API Response Handling

- Don't assume the API always returns data in the response body
- For update operations returning `data: null`, fetch updated data separately if needed

### Header Building

Centralize header construction via a private `_buildHeaders({String? authToken})` method in `ApiService`. Single source of truth for authentication header format.

---

## Locale & Language Management

### Automatic Locale Synchronization

Set locale in **ALL** user state change paths: login, session load, profile update. Keep locale logic centralized in providers, not scattered across UI.

### Form Validation Localization

All validation messages must use `AppLocalizations.of(context)!`. Never hardcode validation messages.

### All User-Visible Strings — ABSOLUTE RULE

**EVERY user-visible string — headings, labels, button text, dialog titles, tab names, placeholders, tooltips, error messages — MUST use `AppLocalizations.of(context)!`. Hardcoding English strings is a defect, not a shortcut.**

**Process — always add ARB keys BEFORE writing widget code:**
1. Add key + English string to `lib/l10n/app_en.arb`
2. Add key + Hebrew string to `lib/l10n/app_he.arb`
3. Run `flutter pub get` (triggers code generation)
4. Use `l10n.yourKey` in the widget

### ARB Strings — No Placeholders

**NEVER use placeholder parameters (`{varName}`) in ARB files.** Build parameterized strings by concatenation in the widget layer instead.

```dart
// ❌ Wrong — ARB placeholder
// "onboardingOtpSentTo": "We sent a code to {email}"

// ✅ Correct — plain ARB + concat in widget
'${l10n.onboardingOtpSentTo} $email'
```

---

## Date & Currency Formatting — Company Locale

**CRITICAL: Dates and currency amounts are ALWAYS formatted using the company locale, NOT the UI language.**

Use extensions from `lib/utils/format_utils.dart`:

```dart
expense.expenseDate.toCompanyDate(locale)   // "5.3.2026" (he) or "3/5/2026" (en)
expense.amount.toCurrency(locale, 'ILS')    // "₪1,234.56"
total.toFormattedNumber(locale)             // "1,234.56"
```

Get locale from `ref.watch(companyLocaleProvider)` (defined in `lib/providers/auth_provider.dart`).

**Rules:**
- **NEVER** use `Localizations.localeOf(context)` for date/currency — that's the UI language
- **NEVER** use `DateFormat` or `NumberFormat` directly — always use the `format_utils.dart` extensions
- **ALWAYS** get locale from `ref.watch(companyLocaleProvider)`
- If a widget needs formatting and is currently `StatelessWidget`, convert to `ConsumerWidget`

---

## Screen Scaffold Layout — Mandatory Pattern

Every app screen MUST follow this exact scaffold structure:

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ← ALWAYS first line

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),                        // ← always first
            Expanded(
              child: SingleChildScrollView(           // ← OUTSIDE ConstrainedContent
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(            // ← INSIDE SingleChildScrollView
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // screen content...
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),                        // ← always last
          ],
        ),
      ),
    );
  }
}
```

**Rules:**
- `AppHeader` is always the **first** child of the root `Column`
- `AppFooter` is always the **last** child of the root `Column`
- Mandatory nesting: `Expanded` → `SingleChildScrollView` → `ConstrainedContent`
  - **WRONG** (causes vertical centering and RTL bugs): `Expanded` → `ConstrainedContent` → `SingleChildScrollView`
- Always wrap `Scaffold` in `buildWithNavigationGuard` (from `FormBehaviorMixin`)
- Use `ConsumerStatefulWidget` + `FormBehaviorMixin` for all screens, even read-only ones
- Use `ConstrainedContent` (not raw `ConstrainedBox`) for standard max-width + responsive padding
- `final l10n = AppLocalizations.of(context)!;` must be the first line of every `build()` method

**Reference implementations:** `lib/screens/profile_screen.dart`, `lib/screens/company_config_screen.dart`

---

## New Screen Checklist — Required Steps Every Time

Follow in order. Do not skip steps.

### Step 1 — Add ARB keys first (before any widget code)

1. Add every string to `lib/l10n/app_en.arb`
2. Add Hebrew translations to `lib/l10n/app_he.arb`
3. Run `flutter pub get`

Never write `Text('Some Label')` as a placeholder to localize later. Start localized.

### Step 2 — Screen class boilerplate

```dart
// lib/screens/my_new_screen.dart
import 'screen_imports.dart';

class MyNewScreen extends ConsumerStatefulWidget {
  const MyNewScreen({super.key});

  @override
  ConsumerState<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends ConsumerState<MyNewScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // ...
  }
}
```

### Step 3 — Add route to router.dart

```dart
case '/employee/my-new-screen':
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const MyNewScreen(),
  );
```

### Step 4 — Add import to screen_imports.dart if needed

Only if the screen introduces a new shared export.

### Step 5 — RTL checklist before calling done

| Check | What to look for |
|-------|------------------|
| All strings via l10n | No hardcoded English in any `Text(...)` |
| `Row` children order | Use leading/trailing, not left/right |
| `CrossAxisAlignment.start` on `Column` | Aligns to reading-direction start |
| `TextAlign.left/.right` hardcoded | Replace with `.start`/`.end` or omit |
| Icon direction | Use `Icons.arrow_back` not `Icons.arrow_back_ios` |
| `EdgeInsets.only(left/right)` | Replace with `EdgeInsetsDirectional.only(start/end)` |

### Step 6 — All widgets inside the screen must also:

- Use `AppLocalizations.of(context)!` — no hardcoded strings
- Use `CrossAxisAlignment.start` on columns
- Use `MainAxisAlignment.spaceBetween` or `start`/`end`

---

## Multi-Platform Navigation

When implementing navigation, ensure all paths work:

1. Desktop header menu
2. Mobile menu sheet (close sheet before navigating)
3. Route registered in `router.dart`
4. Test both desktop and mobile navigation paths

---

## Email Validation

**ALWAYS use the `email_validator` package. Never write regex for email validation.**

```dart
// ❌ Wrong
RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)

// ✅ Correct
import 'package:email_validator/email_validator.dart';
EmailValidator.validate(email)
```

Applies to: `_canContinue`/`_isFormValid` getters, `TextFormField` validators, service-layer pre-validation. Reuse the canonical `EmailInputField` widget wherever possible.

---

## Step-by-Step Implementation

When implementing complex features:

1. **Plan steps**: Break down into logical, sequential steps
2. **Build after each step**: Run `flutter build web` after each change
3. **Verify no errors** before proceeding
4. **Wait for confirmation**: Don't proceed to next step without user approval
5. **Document API responses**: Include expected API responses in spec docs

```
Step 1: Update model → Build → Verify → Wait
Step 2: Add API method → Build → Verify → Wait
Step 3: Add service method → Build → Verify → Wait
Step 4: Update provider → Build → Verify → Wait
Step 5: Create UI screen → Build → Verify → Wait
Step 6: Add routing → Build → Verify → Wait
Step 7: Integration testing
```

---

## Safe Refactoring Process

When reorganizing files:

1. Create new directory structure first
2. Move files using terminal commands
3. Update all import statements in batch
4. Verify with error checking BEFORE assuming success
5. Run `flutter clean` then `flutter pub get` to clear stale build cache
6. Close and reopen affected files to refresh the language server
7. If errors persist after cleaning, they may be stale IDE cache — ask user to reload VS Code window

---

## Import Path Patterns

From `lib/widgets/file.dart`:
- Theme: `import '../theme/app_theme.dart'`
- Models: `import '../models/model_name.dart'`
- Providers: `import '../providers/provider_name.dart'`

From `lib/widgets/header/file.dart`:
- Theme: `import '../../theme/app_theme.dart'`
- Models: `import '../../models/model_name.dart'`
- Sibling: `import 'sibling_widget.dart'`

Each directory level up requires one more `../`.

---

## Incremental Development Approach

When building multi-platform features:

1. **Desktop first** — Build and test desktop version completely
2. **Extract shared logic** — Identify reusable components and data structures
3. **Create shared models** — Single source of truth for data structures
4. **Mobile adaptation** — Build mobile version using shared models
5. **Responsive coordination** — Add breakpoint logic in parent components

---

## Quick .NET → Flutter Reference

| .NET | Flutter/Dart |
|------|--------------|
| `IServiceProvider` | Provider/Riverpod |
| `Task<T>` | `Future<T>` |
| `INotifyPropertyChanged` | `StateNotifier` |
| `HttpClient` | `http` package |
| `System.Text.Json` | `dart:convert` + `fromJson`/`toJson` |
| `IAsyncEnumerable<T>` | `Stream<T>` |
| `appsettings.json` | YAML config files |
| Dependency Injection | Provider pattern |
| LINQ | Iterable methods (`map`, `where`, etc.) |

**Key Dart differences from C#:**
- `_` prefix = private to file (not class)
- No interfaces — use abstract classes
- `late` for lazy init, `const` for compile-time constants
- Mixins with `with` keyword
- No null-coalescing assignment — use `??=`
