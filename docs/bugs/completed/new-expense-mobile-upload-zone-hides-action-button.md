# Bug: New Expense step 1 on mobile -- "Continue" sits below the fold and the page has no scroll to reach it

> **Status: done**

## Resolution

Shipped in **v1.31**, 2026-08-23 — commit `f8d2411` on `develop`, released as
`e74b1cd` on `main`.

`_NewExpenseScreenState._mobileScrollTail` (`lib/screens/new_expense_screen.dart`)
appends 120 px of dead space below the content on mobile, applied through the
`SingleChildScrollView`'s bottom padding. That guarantees the scroll view has
extent instead of trying to predict the visible viewport height — the quantity
that cannot be measured reliably and the reason the original formula failed.

Chosen over the two alternatives on the table: correcting `mobileChrome` to its
real value would have bought back less than the billing banner costs, and pinning
the action button to the bottom of the viewport was a larger change to the screen's
shape that would have had to be repeated per screen. The padding also covers step
2's "Finish" button for free, since it shares the shape. `mobileChrome` and the
leftover-space formula are left in place but no longer load-bearing; the comment
above them now says so.

Desktop is unchanged (24 px top and bottom, as before).

**Verified on the reporting device** — iPhone 14 Pro, portrait, Safari, manager
session with the billing banner showing — on 2026-08-23, after the v1.31 deploy.
"Continue" is reachable without rotating. `flutter analyze` clean (bar the 9
pre-existing info lints tracked in `flutter-analyze-info-lints-cleanup.md`, none
in this file), release build compiles, 36 tests pass.

120 px was enough for this device and this banner. It is a margin, not a
measurement: if a future header addition or a longer banner string ever puts an
action button under the browser chrome again, the tail is the dial to turn, and
the band analysis above explains why turning `mobileChrome` instead would not
help.

## Problem

On an iPhone, step 1 of "New Expense" renders the "upload image here" drop zone
so tall that the "Continue" button below it falls under Safari's bottom toolbar.
The page cannot be scrolled to reach it -- there is no scroll at all. The only
way out is to rotate the phone to landscape and back, which forces a re-layout,
after which the button is visible and tappable.

Business impact: a user who does not think to rotate their phone cannot file an
expense from a phone. Photographing a receipt on a phone is the primary way an
expense enters the system.

Reproduced 2026-08-23 on an **iPhone 14 Pro, portrait, Safari**, logged in as a
**manager**, with the trial-expired billing banner showing. Confirmed on the same
device that **with the billing banner absent, "Continue" is clearly visible.**

## Reproduce Steps

1. On an iPhone 14 Pro in portrait, log in as a manager whose company shows a
   billing banner (trial expired / pending payment), and open New Expense
   (`/user/new-expense`).
2. Step 1 shows the "upload image here" drop zone.
3. Try to reach the "Continue" button below the drop zone, including by
   scrolling.
   -- Expected: the button is visible, or the page scrolls until it is.
   -- Actual: the button is off screen and the page does not scroll at all.
      `AppFooter` is not visible either.
4. Rotate to landscape, then back to portrait.
   -- Actual: layout is correct, "Continue" is visible and tappable.

Contrast case: same device, no billing banner in the header -- "Continue" is
clearly visible and the screen is usable.

## Diagnosis

### The layout is built to fit, so it can never overflow, so it never scrolls

`NewExpenseScreen.build` (`lib/screens/new_expense_screen.dart`, the
`LayoutBuilder` at ~line 1749) does not lay out content and let the page grow. It
measures the space available and sizes the drop zone to whatever is left over:

```dart
const mobileChrome = 270.0;
final uploadHeight = context.isMobile
    ? ((availableHeight - mobileChrome) * 0.85).clamp(120.0, 600.0)
    : (availableHeight * 0.6).clamp(320.0, 600.0);
```

Content height is `0.85 * (availableHeight - 270) + realChrome`, which for any
plausible `realChrome` is less than `availableHeight`. The child of the
`SingleChildScrollView` is always shorter than its viewport, so `maxScrollExtent`
is 0 and the scroll view is inert -- present in the tree, but with nothing to
scroll. The formula traded scrolling away in exchange for a promise that
everything fits on one screen.

That promise is the whole problem. It leaves no margin for error, and there is
no fallback when it turns out to be wrong.

### Something is below the visible area, and it is not just the button

`AppFooter` is the last child of the screen's root `Column`, outside the
`Expanded`, so it is pinned to the bottom of the `Scaffold` and is on screen
whenever the `Scaffold` fits the viewport. It is nowhere in the screenshot.

So the `Scaffold` extends past the bottom of what the iPhone shows. The leading
explanation is that Flutter web lays out into a viewport height that, on iOS
Safari, includes the strip behind Safari's bottom toolbar (the `100vh` /
large-viewport behaviour) -- roughly 80 px on this device. The layout is then
correct by its own arithmetic and wrong on the glass.

### Why it cannot recover on its own

Safari retracts its toolbars to give the page more room, but only in response to
the user scrolling. There is no scroll, so the toolbars never retract, so the
hidden strip never appears. The state sustains itself rather than clearing.

Rotating fires a resize rather than a scroll, which is why it is the only thing
that breaks the deadlock -- and why this reproduces on a real iPhone but not in
desktop devtools phone emulation, which has no retracting chrome.

### The billing banner's role -- the last 10 px, not the cause

The banner is what tipped this over in practice, and the confirmed contrast case
above is the evidence. But it is worth being precise about how much it is
responsible for, because that decides whether the fix can stop at the banner.

Rearranging the formula, with `A` = `availableHeight`, `R` = real chrome inside
the scroll region, and `hidden` = the strip behind Safari's toolbar:

```
overshoot = hidden + R - 229.5 - 0.15 * A
```

Adding the banner to the header reduces `A` by the banner's height `B`, so it
increases the overshoot by `0.15 * B`. The banner measures roughly 67 px
(2 wrapped lines of 13 px Hebrew text plus 20 px padding), so it moves the
button down by about **10 px**.

The 85% factor is why: the formula already gives back 85% of anything the header
takes, so a 67 px banner nets only ~10 px. Which means the layout was sitting
within ~10 px of the fold *before* the banner existed. The banner did not create
the problem; it consumed the last of a margin that was already almost zero.

Anything else worth 10 px does the same thing: a trial message that wraps to
three lines, a slightly different device, a Hebrew string edit, a new element in
the header, one more pixel of Safari chrome in an iOS update. **A fix that only
removes or shrinks the banner will hold until the next 10 px arrives.**

### Ruled out

- **The drop zone swallowing touch scrolls.** Checked: `WebFileDropRegion`
  (`lib/widgets/web_file_drop_region.dart`) is a plain `KeyedSubtree` with
  document-level `dragover`/`drop` listeners only -- no platform view, no DOM
  overlay, nothing that intercepts touch. `ReceiptUploadZone` wraps a
  `GestureDetector` with `onTap` only, and a tap recognizer loses the gesture
  arena to an ancestor `Scrollable`'s vertical drag. Neither blocks scrolling.
  The scroll is missing because there is no extent, not because gestures are
  being stolen.

### One diagnostic settles the remaining uncertainty

The numbers above are estimated off the screenshot. There is also a simpler
variant of the mechanism worth excluding: the content may exceed
`availableHeight` by a few pixels, giving a real but tiny scroll extent that
feels like "no scroll". It fails the footer test above, but it is cheap to
confirm rather than argue about. One run on the device with these logged inside
the `LayoutBuilder` resolves all of it:

- `constraints.maxHeight` (`availableHeight`)
- `MediaQuery.sizeOf(context).height`
- `web.window.innerHeight` and `web.window.visualViewport?.height`
- the scroll controller's `position.maxScrollExtent` after first layout

Do this before writing the fix -- it converts the whole diagnosis above from
inference to measurement.

## Suggested Solution Approach

Stop guaranteeing that the screen fits, and let it scroll instead. A page that
scrolls tolerates the browser mis-reporting its own viewport by any amount; a
page sized to fit exactly is broken by the smallest error, and this one had about
10 px of room. The drop zone is a convenience -- a generous tap and drop target
-- and it should yield to the button the user came to press.

## Suggested Fix

On mobile only; desktop behaviour should not change.

1. Drop the viewport arithmetic on mobile. Give the drop zone a fixed or
   aspect-ratio height, or a `maxHeight` in the 240-320 range, independent of
   `availableHeight`. Delete `mobileChrome` rather than correcting it -- a
   hardcoded guess at the height of widgets the layout already measures will
   drift again the next time the chrome changes, and correcting 270 to the real
   ~284 would buy back less than the banner costs.
2. Let the content be taller than the viewport. Once it genuinely overflows,
   `SingleChildScrollView` has real extent, the button is always reachable, and
   the first scroll gesture makes Safari retract its toolbar and hand back the
   hidden strip.
3. Verify on the iPhone 14 Pro itself, portrait, without rotating, **as a manager
   with the billing banner showing** -- that is the configuration that fails, so
   a build verified without the banner proves nothing. Devtools phone emulation
   does not reproduce the retracting-toolbar half of the mechanism and will pass
   a broken build.
4. Re-check step 2's "Finish" button on the same device and configuration. It has
   the same shape -- a lone primary action beneath a large image area -- but step
   2 renders `ExpenseCreateImagePanel` / the collapsed receipt row rather than the
   drop zone, so it needs its own look rather than being assumed fixed.

Pinning the primary action to the bottom of the viewport on mobile is the
alternative if the above does not settle it, but it is a larger change to the
screen's shape and should not be the first attempt.

## Severity note

`BillingAlertBanner` returns `SizedBox.shrink()` for anyone whose `roleId != 1`
(`lib/widgets/header/billing_alert_banner.dart:41`), so an **employee never sees
the banner** -- and, per the confirmed contrast case, an employee therefore has a
visible "Continue" today. In its current form this blocks **managers filing their
own expenses on a phone**, not the whole employee base.

That is narrower than first filed, but it is not comfortable: the margin is ~10
px, it is consumed by a banner that appears exactly when the company is being
chased for payment, and the same 10 px is available to any future header or
string change for every role.
