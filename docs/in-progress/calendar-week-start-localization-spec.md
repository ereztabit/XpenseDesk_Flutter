# Calendar Week-Start Localization — Story (Post-MVP)

## Status

Post-MVP enhancement. Not blocking. Filed as a separate story from the
"expense editor calendar not loading" bug (docs/bugs/expense-editor-calendar-not-loaded.md),
which is purely about the picker failing to open and is unrelated to which day
the week starts on.

## Context

Different markets start the week on different days:

- Israel: the week starts on **Sunday**.
- Most other markets: the week starts on **Monday**.

Flutter's `showDatePicker` does not expose a `firstDayOfWeek` parameter. The first
column of the calendar grid is taken from the ambient locale's
`MaterialLocalizations.firstDayOfWeekIndex` (0 = Sunday, 1 = Monday, ...), which is
supplied by `GlobalMaterialLocalizations` based on the active `Locale`.

Current behavior in this app (the date pickers were only hardened to *load*, not to
localize the week start):

- Hebrew UI (`he`) -> Sunday-first. Correct for Israel.
- English UI (`en`) -> follows Flutter's `en` data (Sunday / US convention), which is
  **not** the desired Monday for non-Israel markets.

Two gaps:

1. The week start follows the **UI language**, not the **company country**. An
   Israeli company whose user switched the UI to English would get the English
   default, and a non-Israel company would not get Monday.
2. There is no company-country signal available client-side today (see Data Source).

## Goal

Date pickers across the app start the week on the correct day for the company:

- Company country is Israel -> **Sunday**.
- Any other country -> **Monday**.

The picker's display language (month names, OK/Cancel) must stay tied to the UI
language; only the week-start column changes.

## Decision

The week start is keyed off the **company country**, not the UI language:

- Company country is Israel -> Sunday.
- Any other country -> Monday.

This is independent of the UI language: an Israeli company using the English UI
still gets a Sunday-first calendar, and a non-Israel company using Hebrew still gets
Monday. Because there is no company-country signal client-side today, surfacing it
(see Data Source) is a prerequisite for this story. The UI language is explicitly
NOT an acceptable substitute.

## Data Source (prerequisite)

- `UserInfo` (lib/models/user_info.dart) has **no** country field today.
- `companyLocaleProvider` (lib/providers/auth_provider.dart) only exposes the UI
  language code (`he`/`en`).
- Onboarding holds `countryCode` (lib/providers/onboarding_provider.dart) but only
  during the onboarding flow.

This requires surfacing the company country to the logged-in session — e.g. add
a `countryCode` to `UserInfo` / the `/users/me` payload, or expose it via a
`companyCountryProvider` sourced from company config.

## Suggested Approach

Prefer a single global override over editing each `showDatePicker` call.

Add a custom `MaterialLocalizations` delegate that wraps the default localizations
and overrides only `firstDayOfWeekIndex`, leaving every other string intact. Register
it in `lib/main.dart` ahead of `GlobalMaterialLocalizations.delegate` so all date
pickers pick it up automatically.

Sketch:

```dart
class WeekStartMaterialLocalizations extends MaterialLocalizations {
  WeekStartMaterialLocalizations(this._inner, this._firstDayOfWeekIndex);
  final MaterialLocalizations _inner;
  final int _firstDayOfWeekIndex;

  @override
  int get firstDayOfWeekIndex => _firstDayOfWeekIndex; // 0 = Sunday, 1 = Monday

  // Delegate everything else to _inner ...
}
```

Resolve `_firstDayOfWeekIndex` from the company country: Israel -> 0 (Sunday),
otherwise -> 1 (Monday).

Alternative (heavier, not recommended): wrap each `showDatePicker` call with the
`builder:` parameter and `Localizations.override`, but that also overrides the
display language and must be repeated per call site.

## Affected Files

- `lib/main.dart` — register the custom `MaterialLocalizations` delegate.
- (New) a small `lib/l10n/week_start_localizations.dart` (or similar) for the
  wrapper delegate.
- Data-source change to surface company country (e.g. `lib/models/user_info.dart` +
  `/users/me` mapping, or a new `companyCountryProvider`).

The three existing `showDatePicker` call sites need no change if the global delegate
approach is used:

- `lib/screens/new_expense_screen.dart`
- `lib/screens/employee_expense_detail_screen.dart`
- `lib/widgets/expenses/mobile_expense_modal.dart` (currently has no live call site)

## Manual Verification

- Hebrew UI, Israeli company -> calendar week starts on Sunday.
- English UI, non-Israel company -> calendar week starts on Monday.
- English UI, Israeli company -> calendar week starts on Sunday.
- Hebrew UI, non-Israel company -> calendar week starts on Monday.
- Month names / OK / Cancel stay in the active UI language in all cases.
- RTL (Hebrew) calendar still lays out correctly.

## Out of Scope

- The "calendar not loading" fix (separate bug, already addressed).
- Any change to how dates are formatted for display (`toCompanyDate`), which is a
  distinct concern from the picker's week-start column.
