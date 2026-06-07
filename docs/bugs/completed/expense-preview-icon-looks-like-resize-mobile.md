# Bug: Expense "preview" icon looks like a resize icon (mobile)

> **Status: done**

## Resolution

Replaced the `open_in_full` (resize-looking) glyph with `Icons.visibility_outlined`
(eye) across the whole add/edit-expense preview flow, and removed the redundant
hover-only "expand" pill that duplicated the icon and never appeared on touch.

Now there is a single, always-visible eye button per preview; tapping the image
still expands it.

Files:
- `lib/widgets/expenses/expense_modify_image_panel.dart` — removed center hover
  pill (`_HoverableNetworkImage` -> stateless `_TappableNetworkImage`); corner
  button -> eye; dropped unused `dart:ui` import.
- `lib/widgets/expenses/expense_create_image_panel.dart` — removed hover pill
  (`_HoverableReceiptImage` -> `_TappableReceiptImage`); desktop bar + mobile
  overlay -> eye.
- `lib/screens/new_expense_screen.dart` — Step-0 preview corner button and
  collapsed-receipt-row button -> eye.

## Problem

When adding an expense on mobile, the small "preview" icon looks like a resize
icon. The intent is unclear.

## Reproduce Steps

1. On mobile, add an expense with an attachment.
2. Look at the preview control.
   -- Expected: a clearly recognizable "preview" affordance.
   -- Actual: the glyph reads as a resize icon.

## Suggested Solution Approach

Make the preview action unmistakable for both sighted and screen-reader users.

## Suggested Fix

- Swap the current glyph for `Icons.visibility` / `Icons.visibility_outlined`
  (eye).
- Wrap it in a `Tooltip` (localized "Preview") and set a `semanticLabel` so the
  intent is clear for assistive tech.
