# Bug: Startup frame throws a RenderFlex overflow at a 1x1 viewport

> **Status: new**

## Problem

Every debug launch prints a `RenderFlex overflowed by NNN pixels on the bottom`
exception to the console, naming whichever screen happened to load first. There
is no user-visible symptom: nothing renders wrong, and release builds do not run
overflow assertions at all.

The cost is console noise, not broken behaviour. It looks alarming, it names a
different screen every time depending on the entry URL, and it has already
burned review time twice being investigated as a real defect. Filed so the
diagnosis below is on record and nobody has to re-derive it from a render dump.

## Reproduce Steps

1. `flutter run -d chrome` on any route.
2. Watch the debug console during startup.
   -- Expected: no exceptions.
   -- Actual: `A RenderFlex overflowed by 760 pixels on the bottom`, pointing at
      the root `Column` of the first screen rendered.

Observed on `/admin/companies`; equally reproducible on any of the 17 screens
that use the standard scaffold. Loading `/dashboard` first reports that screen
instead, which is the quickest way to confirm it is not screen-specific.

## Diagnosis

Not screen-specific and not caused by any one feature. Confirmed from the render
dump:

- The root `Column` is laid out with `BoxConstraints(0<=w<=1.0, 0<=h<=1.0)` --
  Flutter web renders one frame at a 1x1 canvas before the real viewport
  dimensions arrive.
- Inside that 1px box: `AppHeader` is a fixed 56px and cannot shrink; the
  `Expanded` middle correctly collapses to 0; `AppFooter` balloons to **705px**
  because its `Wrap` wraps the copyright line one character per row at width 1.
- 56 + 0 + 705 = 761 in a 1px box, hence the 760px overflow.

All 17 screens with `AppFooter()` use the same
`Column[AppHeader, Expanded, AppFooter]` shape that `CLAUDE.md` mandates, so any
of them overflows whenever viewport height is less than header + footer. In
practice that is only the startup frame.

## Suggested Solution Approach

Make the standard screen scaffold tolerate a degenerate viewport instead of
asserting, so the console stays clean and real errors are not buried in noise.

## Suggested Fix

There is no cheap version. Clamping `AppFooter`'s runaway height does not fix it:
the 56px header alone still exceeds a 1px frame, so the fix has to handle
"header + footer taller than the viewport" generally.

The right fix is to extract a shared `AppScaffold` wrapping the
`Scaffold` + `backgroundColor` + `Column[AppHeader, ..., AppFooter]` and migrate
the 17 screens onto it, with the degenerate-height case handled in that one
place. That consolidation is worth doing on its own merits -- 17 hand-written
copies of the same scaffold is duplication regardless of this bug -- and
`CLAUDE.md`'s "Screen Scaffold Layout" section would be updated to mandate
`AppScaffold` rather than the literal `Column`.

Scope it as a scaffold refactor, not as a bug fix. Patching a single screen would
mask the symptom on one of 17 and wrongly imply that screen is special.

Priority note: `[Technical][P3]`. No user impact, debug-only, one frame. Do this
when the scaffold is being touched for another reason; it does not justify a
17-file change on its own.
