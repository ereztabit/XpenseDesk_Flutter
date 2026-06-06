# Bug: Expense analysis detail dates should use long "June 1 2026" format

> **Status: new**

## Problem

In the detail part of the Expense Analysis screen, the cycle date range is shown
in the short numeric format (e.g. "1.6.2026" / "6/1/2026"). It should use the
long, human-readable format like "June 1 2026".

## Reproduce Steps

1. Open Expense Analysis as a manager.
2. Look at the date range under the cycle label in the detail card.
   -- Expected: long format, e.g. "June 1 2026 - June 30 2026".
   -- Actual: short numeric format from `toCompanyDate`.

## Suggested Solution Approach

Render the detail-card cycle date range using a long month-name format, still
driven by the company locale (not the UI language).

## Suggested Fix

The date range is built in `lib/widgets/analysis/detail_card.dart` (around line
82):
`'${row.fromDate.toCompanyDate(widget.locale)} - ${row.toDate.toCompanyDate(widget.locale)}'`.

`toCompanyDate` (in `lib/utils/format_utils.dart`) produces the short numeric
format. Add a new company-locale-aware long-date extension (e.g.
`toCompanyLongDate(locale)`) in `format_utils.dart` and use it here. Per project
rules, keep formatting in `format_utils.dart` -- do not call `DateFormat`
directly in the widget, and drive the locale from `companyLocaleProvider`, not the
UI language.

Note: confirm the exact target style ("June 1 2026" vs "June 1, 2026") and how it
should read under a Hebrew company locale.
