# Bug: Activity panel shows status transition with an arrow (duplicates each status)

> **Status: done**

## Resolution

The activity timeline rendered each entry as a `from -> to` transition (arrow +
both status labels), which showed every status twice on screen. Now each entry
renders only the resulting (new) status; entries are ordered by timestamp, so the
sequence already conveys the full history. Removed the now-unused `fromLabel` /
`isRtl` locals and the arrow glyph.

Files:
- `lib/widgets/sheet_review/sheet_activity_timeline_entry.dart`.

## Problem

When reviewing a sheet, the activity panel below shows status transitions
(old -> new). We only need to see the new status; the arrow duplicates every
status twice on screen.

## Reproduce Steps

1. As a manager, review a sheet and look at the activity panel.
2. Read the status entries.
   -- Expected: each entry shows only the new status.
   -- Actual: each entry shows `from -> to`, duplicating statuses.

## Suggested Solution Approach

Show only the resulting status per activity entry; ordering by timestamp already
conveys the sequence.

## Suggested Fix

- In the activity-panel item builder, render only the new status per entry; drop
  the `from -> to` arrow rendering.
