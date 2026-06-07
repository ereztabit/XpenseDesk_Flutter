# Bug: AI box "Edit" button is unstyled and barely visible on mobile

> **Status: done**

## Resolution

Replaced the bare `GestureDetector` (12px muted icon + text) Edit/Undo toggle in
the AI detected-details box with a real themed `AppButton` (`normal` variant —
gray fill, border, dark text, purple-on-hover), so it reads as a button and is
clearly visible on mobile. Edit and Undo are one toggle, so both states share the
styling.

Added an additive `dense` flag to `AppButton` (smaller padding/font/tap-target;
default `false`, nothing else affected) for compact inline controls like this.

Files:
- `lib/widgets/app_button.dart` — new `dense` option.
- `lib/screens/new_expense_screen.dart` — Edit/Undo toggle now uses `AppButton`.

## Problem

In the AI box when adding an expense, the Edit button caption is not styled (it
looks like plain text) and is barely visible on mobile.

## Reproduce Steps

1. On mobile, add an expense and trigger the AI detected-details box.
2. Look at the Edit action.
   -- Expected: a clearly styled button matching the adjacent Undo button.
   -- Actual: Edit reads as plain text and is hard to see.

## Suggested Solution Approach

Edit and Undo should read as a matched pair.

## Suggested Fix

- Promote Edit from a text caption to a real button styled identically to the
  adjacent Undo button (same `AppButton` variant / widget, same padding, size,
  and color tokens).
- Reuse the shared `AppButton` widget instead of styling inline so the two stay
  in sync.
