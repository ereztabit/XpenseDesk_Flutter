## Problem

On mobile the AppFooter does not stretch to 100% screen width. The Container in
app_footer.dart has no explicit width, so Flutter shrink-wraps it to the content
width instead of filling the available horizontal space.

## Reproduce Steps

1. Open any authenticated page on a mobile viewport.
2. Scroll to the bottom to see the footer.
   -- Observe: the footer background and border-top do not reach the screen edges.
   -- Expected: the footer fills the full screen width like the header does.

## Suggested Fix

File: lib/widgets/app_footer.dart (line 13)

Add width: double.infinity to the Container so it always stretches full width:

  return Container(
    width: double.infinity,   // <-- add this
    decoration: BoxDecoration(
      ...
    ),
    ...
  );
