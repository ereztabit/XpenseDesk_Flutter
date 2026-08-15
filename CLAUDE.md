# CLAUDE.md — XpenseDesk Flutter

## Background

I am a senior developer with 20+ years of coding experience, specializing in .NET web development with strong vanilla JavaScript expertise. I am learning Flutter to expand my mobile development capabilities.

## Project Context

This Flutter application is **XpenseDesk** — an AI-powered expense approval tool for small businesses. The complete product specification and MVP scope are defined in:

- [AI Expense Approval MVP North Star](docs/product/ai_expense_approval_mvp_north_star.md) — Complete product vision, feature set, user journeys, and business rules
- [MVP Screen Map](docs/product/mvp_screen_map.md) — Screen definitions and user flows

**These documents are the source of truth for what we're building.** All implementation decisions should align with the MVP definition and user journeys described in these specifications.

## Branching & Release — READ FIRST

**The authoritative method lives in [docs/branching-and-release.md](docs/branching-and-release.md). Follow it exactly.**

- **`develop` is the trunk** — all work and commits happen there. **Never commit straight to `main`.**
- **`main` is the release/deploy branch** — code reaches it only by merging `develop`. **Pushing `main` is the deploy** (CI auto-deploys the web build to Azure Static Web Apps). Pushing `develop` never deploys.
- **Never commit, push, or merge without the user's explicit, in-turn consent.** Invoking the `start-feature` / `finish-feature` / `ship-feature` skills counts as consent for the steps those skills perform.
- **Three phases:** `start-feature` (begin on `develop`) -> `finish-feature` (review + checks + commit/push `develop`, **no merge, no deploy**) -> `ship-feature` (merge `develop` -> `main` + push = deploy).
- **"Finish the feature" means commit/push `develop` only** — it is NOT a release. Releasing is the separate, explicit `ship-feature` step. No manual deploys.
- Every shipped feature gets one row in the root [README.md](README.md) feature log.

## Work Tracking — current-work.md

**ALWAYS read `docs/current-work.md` at the start of every conversation.**

`docs/current-work.md` is a pure backlog: it holds **open work only, never
history**. An item is either open (in this file) or done (deleted from it, with
its record in `docs/completed/` or `docs/bugs/completed/`). There is no `[x]`
state and no "done" section — a finished item leaves no trace here.

When starting work on any feature or task:
1. Move it from its backlog section to a `## Currently Working On` section at the
   top of `docs/current-work.md` (create that section if it isn't there — it only
   exists while something is actually in progress)
2. Note it as in-progress there
3. When it is done, **delete the item outright** — remove it from "Currently
   Working On" and do not leave a `[x]` line behind. Remove the whole
   "Currently Working On" section once nothing is in progress.

**Never start implementing without updating `current-work.md` first.**

### "What's pending?" — MANDATORY response format

When the user asks **"what's pending"** — or any variant ("what's open", "what's
left", "what's on the list", "what are the open bugs", "what do we have") — read
`docs/current-work.md` and reply with **one numbered table and nothing else**.
No prose summary, no per-section headings, no recommendations unless asked.

| Column | Content |
|--------|---------|
| `#` | Sequential number across the whole table, `1..N` — the user picks work by number |
| `P` | Priority from the line's tag: `P1`, `P2`, `P3` |
| `Tag` | Category from the line's tag: `Business`, `Security`, `Technical`, `LookAndFeel` |
| `Type` | `Bug` or `Feature` |
| `Item` | One short line — the gist, not the full sentence from the file. Link the spec/bug doc here |
| `Status` | `IN PROGRESS`, `Open`, or `Deferred` |

Every line in `current-work.md` carries a `[Category][P#]` prefix — the legend
lives in that file's `## Tags` section. Report the tags as written; never invent
one for an untagged line, show it as `—` and say which lines need tagging.

Row order:
1. Everything in `## Currently Working On` — first, `IN PROGRESS`.
2. Then by priority, `P1` before `P2` before `P3`. Within a priority, Bugs
   before Features.
3. Anything marked `(deferred)` / `(deferred to v2)` — last, `Deferred`,
   regardless of priority.

Rules:
- **List every open item.** Never truncate, sample, or collapse to "and N more".
- Numbering is contiguous — a picked number must map to exactly one row.
- If nothing is in `## Currently Working On`, put a single line above the table:
  `Nothing in progress right now.`
- When the user answers with a number, that row is the item to work on — go
  straight to `start-feature` for it.

When the user asks to "clean up" `current-work.md`:
- Delete every completed item (any `[x]` line, any entry marked DONE), including
  stale "Currently Working On" entries — history belongs in the `completed/`
  folders, not here
- Cross-check that `## report bugs (pending)` lists every open doc in
  `docs/bugs/` — the file is the single index, and open bugs go missing from it
- Fix typos in section headers while you're there

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
    ├── current-work.md                          # Active work + backlog TODOs
    ├── README.md                                # Docs index
    ├── product/                                 # Source of truth
    │   ├── ai_expense_approval_mvp_north_star.md
    │   └── mvp_screen_map.md
    ├── api-guides/                              # API reference docs
    │   ├── authentication_client_guide.md
    │   ├── client-onboarding-company-api-guide.md
    │   ├── expense-api-guide.md
    │   ├── users_api_documentation.md
    │   └── expenses-analysis-api-guide.md
    ├── bugs/                                    # Open bug reports (one file each)
    │   └── completed/                           # Closed bug reports (archive)
    ├── backlog/                                 # Specs for open work NOT started
    ├── in-progress/                             # ONLY what we work on right now
    └── completed/                               # Shipped to production
        └── ExpenseSheetsTransformation/         # (folders allowed here too)
```

**Spec folders track reality, not intent:**

| Folder | Means |
|--------|-------|
| `docs/backlog/` | Open feature, nobody working on it. Indexed in `current-work.md`. |
| `docs/in-progress/` | Being worked on **right now**. **Empty when nothing is in flight** — that is normal. |
| `docs/completed/` | Shipped to production (merged is not enough). |

A spec moves `backlog/` → `in-progress/` when work starts, → `completed/` when it
ships, and **back to `backlog/` if the work is paused, dropped, or only partly
built**. Never park a spec in `in-progress/` for work nobody is doing, and never
author a new spec straight into `completed/`. Repoint inbound links on every move
(they hide in `docs/README.md`, other specs, closed bug docs, and Dart doc
comments in `lib/`).

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

**Screen decomposition — MANDATORY:**
A screen file is an orchestrator: it owns state, providers, and top-level layout only. Every distinct visual section (card, chart, table, filter pane) must be a separate `StatelessWidget` or `ConsumerWidget` in `lib/widgets/<feature>/`. The screen passes data and callbacks down as constructor parameters — no business logic inside child widgets.

- Screen file target: < 200 lines after extraction
- Widget files: one primary widget per file, named after the widget class
- Do not inline card/chart/table build methods as private `_build*` helpers on the screen state — extract them to real widget classes instead

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

### AppTheme Color Tokens — Complete List

**ALWAYS read `lib/theme/app_theme.dart` before using any color token. Never guess a token name.**

Defined static colors: `background`, `foreground`, `card`, `cardForeground`, `primary`, `primaryForeground`, `muted`, `mutedForeground`, `border`, `destructive`, `accent`, `success`, `primaryTint`, `primaryDark`, `teal`, `borderMedium`, `amber`.

Common mistakes:
- `AppTheme.surface` — **does not exist**. Use `AppTheme.card` for white surfaces.
- `AppTheme.white` — **does not exist**. Use `AppTheme.card` or `Colors.white`.

### Button Types — Themed vs Unthemed

`app_theme.dart` defines explicit styles for: `ElevatedButton`, `FilledButton`, `TextButton`.

**`OutlinedButton` has NO theme defined** — it renders with Material 3 defaults which may be low-visibility against the app background. Prefer the themed button types. If `OutlinedButton` is needed, apply an explicit `style:` override.

### Dropdown Widgets

Use `DropdownMenu` (Material 3). **Do not use `DropdownButtonFormField`** (deprecated).
Key differences: `initialSelection`, `dropdownMenuEntries`, `onSelected`, `inputDecorationTheme`.

**`DropdownMenu` — two crash/visual pitfalls:**

**1. Never use `expandedInsets: EdgeInsets.zero` when the dropdown has an explicit `width`.**

`expandedInsets: EdgeInsets.zero` tells the dropdown overlay panel to expand to fill the parent's width.
On Flutter web this causes a `child._parent == this` assertion crash (`rendering/object.dart`) on window
resize — the overlay recalculates layout against a parent that has already been torn down.

- Only use `expandedInsets` for a true full-width dropdown with no explicit `width`.
- For any fixed-width dropdown (`width: 180`), **omit `expandedInsets` entirely**.

**2. Always set `isCollapsed: true` when constraining height.**

Without it, Flutter's `InputDecoration` reserves vertical space for the label above the content line,
pushing the trailing arrow icon below vertical center even when `maxHeight` is capped.
Pair it with explicit `contentPadding` to re-center the text.

**Correct template for a fixed-height, fixed-width `DropdownMenu`:**
```dart
DropdownMenu<String?>(
  width: 180,
  inputDecorationTheme: InputDecorationTheme(
    isCollapsed: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    constraints: const BoxConstraints(minHeight: 36, maxHeight: 36),
    border: OutlineInputBorder(...),
    enabledBorder: OutlineInputBorder(...),
  ),
  // expandedInsets — omit when width is explicit
)
```

---

## API Patterns & Best Practices

### Reusable Validation Helpers

Extract repeated validation patterns into private helper methods (e.g., `_validateResponse`, `_validateSessionToken`). Don't repeat validation logic across service methods.

### API Response Handling

- Don't assume the API always returns data in the response body
- For update operations returning `data: null`, fetch updated data separately if needed

### Header Building

Centralize header construction via a private `_buildHeaders({String? authToken})` method in `ApiService`. Single source of truth for authentication header format.

### ApiService is the Only HTTP Layer

**NEVER use `http.*` directly inside service classes.** All HTTP calls — including multipart uploads — must go through a method on `ApiService`. If a new HTTP pattern is needed (e.g. `postMultipart`), add the method to `ApiService` first, then call it from the service.

```dart
// ❌ Wrong — raw http in service class
final request = http.MultipartRequest('POST', uri);

// ✅ Correct — delegate to ApiService
final response = await _apiService.postMultipart('/api/...', files, authToken: token);
```

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

## Shared Widgets — LOOK HERE BEFORE BUILDING ONE

**Before writing any new container-shaped widget — a table, a card shell, a
scroll region, a filter, an input — check this table first.** Rebuilding one of
these is the most expensive mistake available in this codebase: it passes every
CR rule, because all six of them only inspect the file you wrote.

| Widget | File (`lib/widgets/`) | Reach for it when |
|--------|------------------------|-------------------|
| `StickyReportTable` | `sticky_report_table.dart` | **Any data-dense table.** Sticky header, dual scroll with visible scrollbars, selectable body, loading/error states |
| `SectionTable` | `section_table.dart` | Collapsible card table for a summary section (not for report tables — no horizontal scroll) |
| `ConstrainedContent` | `constrained_content.dart` | Page body max-width + responsive padding |
| `AppHeader` / `AppFooter` | `header/app_header.dart`, `app_footer.dart` | Standard screen chrome |
| `RefreshableScrollView` | `refreshable_scroll_view.dart` | Scrolling page body with pull-to-refresh |
| `AppButton` | `app_button.dart` | Any button |
| `ModuleTabBar` | `module_tab_bar.dart` | Tab strip for a multi-section module. **Not** Material `TabBar` — the caller owns the `TabController` so a tap can await a guard before switching |
| `ActionIconButton` | `action_icon_button.dart` | 32×32 icon button in a table/list action column |
| `SearchButton` | `search_button.dart` | 40px Search CTA matching the filter triggers |
| `EmailInputField` | `email_input_field.dart` | Any email input |
| `TagInput` | `tag_input.dart` | Multi-entry email/tag input |
| `AppRadioGroup` | `app_radio_group.dart` | Radio group |
| `DateRangeFilter` | `date_range_filter.dart` | from→to date-range filter |
| `ErrorAlert` | `error_alert.dart` | Inline error banner |
| `LanguageSwitcher` | `language_switcher.dart` | EN/HE picker — drop it into any header, no wiring needed |
| `SelectableScope` | `selectable_scope.dart` | Make a content region copy-pasteable |
| `RouteRedirector` | `route_redirector.dart` | Spinner + replace the route next frame |
| `LastActionConfirmDialog` | `last_action_confirm_dialog.dart` | Confirm before an irreversible per-expense action |
| `AiBadge` | `ai_badge.dart` | The `'AI'` initialism — never copy the literal |

**Reusing a shell means adopting its constraints on your content, not just its
chrome.** Read the widget's doc comment for what it *requires*, not only what it
provides. Worked example: `StickyReportTable` wraps its body in a
`SelectionArea`, so its rows must be **stateless** — a hover `setState` inside
one re-registers text selectables on every mouse move and trips
`SelectableRegion: _selectable == null is not true`. That is why the report
tables use zebra striping instead of a hover tint.

### Keeping this table honest

**An inventory nobody updates is worse than none** — a stale table gives false
confidence that nothing suitable exists. So the table is verified, not trusted.

**Before adding any new widget, run this:**

```bash
for f in lib/widgets/*.dart; do grep -q "$(basename $f)" CLAUDE.md || echo "NOT IN INVENTORY: $(basename $f)"; done
```

It must print **nothing**. Any output means a root-level widget exists that this
section has never heard of, and the table can no longer be trusted to answer
"does something like this already exist?"

When it prints something:

1. **Tell the user the inventory is stale**, list what turned up, and offer to
   refresh it.
2. **Do not silently rewrite this table mid-task.** `CLAUDE.md` is a checked-in
   project instruction file; editing it as a side effect of a feature drags an
   unrelated change into that feature's diff. Refreshing the inventory is its own
   small, deliberate task.
3. Meanwhile, read the flagged files yourself before concluding nothing fits.

The table covers `lib/widgets/` **root only** — the canonical shared pieces.
Feature subfolders (`lib/widgets/<feature>/`) also hold reusable widgets, so
always `ls` the relevant one too.

**Deliberately not listed** (kept here so the check above stays silent): mixins
and guards used via other rules — `auth_gate.dart`, `form_behavior_mixin.dart`,
`step_guard_mixin.dart`; and single-purpose pieces nobody would rebuild by
accident — `dashboard_greeting.dart`, `microsoft_logo.dart`,
`shake_on_demand.dart`, `web_file_drop_region.dart`.

**If you add a new shared shell, add a row above** and document its content
requirements in its own doc comment. If you add a widget that is deliberately
*not* a shared shell, name it in the paragraph above so the check stays quiet.

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

**Every app route must be wrapped in `AuthGate`.** A bare route without `AuthGate` will redirect to login on direct URL access because `AppHeader` detects no session. Dev/utility tools should be dialogs opened from within authenticated screens — not standalone routes.

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

### Step 6 — Reuse first, then create the widget files you still need

Before writing any UI code, look at the screen spec and identify every distinct visual section. Then, **for each section, in this order**:

1. **Verify the inventory, then look for an existing widget.** Run the staleness check from [Keeping this table honest](#keeping-this-table-honest) — if it prints anything, say so and offer to refresh before relying on the table. Then check the [Shared Widgets](#shared-widgets--look-here-before-building-one) table, then `ls lib/widgets/` and `lib/widgets/<related-feature>/`. Open any candidate whose name is even close — read the file, do not judge by filename. `StickyReportTable` sounds feature-specific and is in fact the generic report-table shell; that misread is exactly how it once got rebuilt from scratch.
2. **If one fits, use it** — and read its doc comment for what it requires of the content you put inside it, not just what it gives you.
3. **Only if none fits**, create the section as its own file under `lib/widgets/<feature-name>/` **first**, then compose it in the screen.

Record the outcome — which shared widget you reused, or why none fit — in the CR (Rule 7). "I didn't find one" is not an answer; name what you looked at.

- Each card, chart, table, and filter pane → separate `StatelessWidget` / `ConsumerWidget` created upfront
- Screen file should stay < 200 lines — just state, providers, and layout
- Never write `_build*` private helpers on the screen state class — if it's worth building, it's worth its own file
- Widget files follow the same ARB / RTL rules as the screen

### Step 7 — All widgets inside the screen must also:

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

## Buttons — AppButton Widget

**ALWAYS use `AppButton` (`lib/widgets/app_button.dart`) for all buttons. Never use raw `ElevatedButton`, `FilledButton`, or `OutlinedButton` directly.**

```dart
import '../widgets/app_button.dart';

AppButton(
  label: l10n.saveChanges,
  variant: AppButtonVariant.primary,
  onPressed: _handleSave,
  icon: Icons.save,       // optional
  isLoading: _isSaving,   // optional — shows spinner, disables tap
)
```

**Available variants:**

| Variant | Regular | Hover |
|---------|---------|-------|
| `primary` | Purple bg, white text | Lighter purple |
| `destructive` | Pink/red bg, white text | Lighter pink |
| `success` | Green bg, white text | Lighter green |
| `normal` | Gray bg, dark text, gray border | Purple bg, white text |
| `ghost` | Transparent, dark text | Light gray bg |

All variants enforce: `borderRadius: 12`, pointer cursor on web, standard padding, consistent hover transitions.

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

## Code Review — Mandatory After Every Change

**ABSOLUTE RULE: every code change must be followed by a CR pass per [.claude/commands/code-review.md](.claude/commands/code-review.md).**

The CR enforces seven rules. **Rule 7 is the one to run first** — Rules 1–6 only
inspect the files you wrote, so all six pass cleanly on a widget that should
never have existed.

1. No file > 200 lines; every visible UI component is its own widget in its own file.
2. Pure functions on domain data live in `lib/utils/<theme>_utils.dart`; HTTP/business logic lives in `lib/services/<theme>_service.dart`. Widgets do not house derived-data math.
3. No hardcoded currency symbols — every amount uses `num.toCurrency(companyLocale, currencyCode)`.
4. No hardcoded captions — every user-visible string uses `AppLocalizations.of(context)!`. Brand initialisms like `'AI'` live in **one** shared widget, not copy-pasted.
5. Flutter modern-patterns hygiene — no `withOpacity`, no `EdgeInsets.only(left:|right:)`, no `TextAlign.left|right`, no `arrow_back_ios`, no raw `http.*` outside `ApiService`, no ARB placeholders.
6. Responsive overflow risk — icon-button columns inside `Row` use `SizedBox(width: N)` not `Expanded(flex:)` so they have a hard minimum at narrow viewports.
7. Reuse — every new container-shaped widget names the shared widget it reused, or states which candidates were read and why none fit. Not greppable by design: reuse is a relationship between your diff and the code you did *not* touch.

Invoke `/code-review` after every change. Findings categorized blocker / should-fix / nit. Wait for user approval before applying fixes.

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
- **L10n: `import '../generated/l10n/app_localizations.dart'`** — widgets cannot use `screen_imports.dart`

From `lib/widgets/header/file.dart`:
- Theme: `import '../../theme/app_theme.dart'`
- Models: `import '../../models/model_name.dart'`
- **L10n: `import '../../generated/l10n/app_localizations.dart'`**
- Sibling: `import 'sibling_widget.dart'`

From `lib/screens/file.dart`:
- L10n comes via `screen_imports.dart` (already re-exported — do not add a separate import)

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

## Cross-Project References

- **Backend backlog:** `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\001_Backlog.md` — server-side bugs, features, and test suite tracking

### Filing a Backend Bug

1. Create a new `.md` file in `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\bugs/` with a descriptive kebab-case name
2. Write in plain text with three sections:
   - **Problem** — what's wrong, business perspective
   - **Reproduce** — steps to trigger it
   - **Suggested Solution** — what should happen, business-level (not code-level)
3. Add a one-line item to `001_Backlog.md` referencing `docs/bugs/<filename>.md`

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
