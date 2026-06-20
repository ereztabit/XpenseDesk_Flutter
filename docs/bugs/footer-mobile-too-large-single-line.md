# Bug: Footer on Mobile Is Too Large — Should Be a Single Line

> **Status: in progress**

## Problem

On mobile the footer takes up too much vertical space. It stacks the legal links
on one row and the copyright line below them, producing a tall multi-line block.
It should collapse to a single, compact line.

## Reproduce Steps

1. Open the app on a narrow viewport (< 600px) on any authenticated screen.
2. Scroll to the bottom.
   -- Expected: A single compact footer line.
   -- Actual: The footer wraps to multiple lines (legal links stacked above the
      copyright text), making it unnecessarily tall.

## Suggested Solution Approach

Make the mobile footer a single line. Keep it compact and centered.

## Suggested Fix

`lib/widgets/app_footer.dart` — the `isMobile` branch (`constraints.maxWidth < 600`)
currently builds a `Column` with a `Wrap` of legal links plus a separate copyright
`Text`. Collapse this to a single line. Note: bug
`move-legal-links-to-main-menu.md` proposes moving Privacy Policy / Terms of
Service out of the footer entirely into the main menu — if that lands first, the
mobile footer reduces to just the copyright line, which naturally satisfies this.
Otherwise, lay the links + copyright out on one line (e.g. reduce font size /
padding and use a single `Row`/`Wrap` that stays on one line). Coordinate the two
fixes.
