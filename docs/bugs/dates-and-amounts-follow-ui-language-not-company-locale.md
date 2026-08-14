# Bug: Dates (and amounts) follow the UI language instead of the company locale

> **Status: new**

## Problem

An Israeli company viewing the app in English sees US-format dates. On the New
Expense "Detected details" card the expense date renders as `7/24/2026` where an
Israeli company should always see `24.7.2026` — the date format is a property of
the company, not of the language the user happens to be reading in.

Reported from the AI detected-details card, but it is almost certainly app-wide:
`companyLocaleProvider` is the single source every date and every amount is
formatted through, and it currently returns the **UI language**:

```dart
// lib/providers/auth_provider.dart:206
final companyLocaleProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
```

`localeProvider` is the UI language selector, so switching the app to English
re-formats every `toCompanyDate` / `toCurrency` / `toFormattedNumber` call in the
app — dates, thousands separators, and currency symbol placement alike. This is
the exact thing CLAUDE.md forbids under "Date & Currency Formatting — Company
Locale": *"Dates and currency amounts are ALWAYS formatted using the company
locale, NOT the UI language."*

Filed as look-and-feel / low priority per the reporter, but note the blast
radius is every screen that shows a date or an amount, not one card.

## Reproduce Steps

1. Log in to a company whose locale is Israeli (base currency ILS, Hebrew
   company).
2. Switch the UI language to English.
3. Open New Expense, scan a receipt, and look at "Detected details" -> Expense
   Date.
   -- Expected: `24.7.2026` (company locale, unchanged by the UI language).
   -- Actual: `7/24/2026` (US format, because the UI is in English).
4. Switch the UI back to Hebrew and look again -- the same date now reads
   `24.7.2026`. The value did not change; only the language did.
5. Spot-check other screens (dashboard, sheet review, expenses analysis,
   billing) in both languages to confirm the scope.

## Suggested Solution Approach

A company has one date/number format and it never moves. Reading the app in
English must not turn an Israeli company's dates into American ones, and must
not re-group or re-symbol its amounts. The UI language should control only the
words.

## Suggested Fix

Needs a short investigation before coding — the fix is one provider, but the
input it should read has to be confirmed:

1. Decide what the company locale actually is. `UserInfo` carries `languageId`,
   `languageCode` and `currencyCode` (`lib/models/user_info.dart`), but
   `languageCode` there looks like the *user's* preferred language, which is
   what drives `localeProvider` in the first place. Check the company API
   (`docs/api-guides/company-configuration-api.md`) for a company-level locale /
   country field. If none exists, this needs a backend change and the client
   should derive from something stable in the meantime (base currency ->
   locale is a defensible stopgap: ILS -> `he`).
2. Point `companyLocaleProvider` at that value instead of
   `ref.watch(localeProvider).languageCode`. Every call site already goes
   through this provider, so nothing else should need touching.
3. Re-check the screens in both languages. Watch for places that read
   `Localizations.localeOf(context)` for a date or amount — those are the
   separate, already-forbidden variant of the same bug.
4. Worth a unit test on the provider once the source of truth is settled.
