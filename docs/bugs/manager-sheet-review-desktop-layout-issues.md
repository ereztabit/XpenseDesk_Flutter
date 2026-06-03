## Problem

Four layout and UX issues on the manager Sheet Review screen (desktop).

1. Content does not use available screen width.
   ConstrainedContent enforces a hard maxWidth of 720px (constrained_content.dart line 25).
   On a wide desktop screen the content sits in a narrow strip with large empty margins
   on both sides. The available width between the left menu and the right logo is wasted.

2. Date column is too narrow -- content wraps.
   The Date column has flex 16 out of a total flex sum of 91. At 720px container width
   minus padding and the fixed 88px actions column, the Date column gets roughly 98px.
   "December 12th 2025" at 14px font requires ~120px and wraps onto two lines.

3. Row borders between expenses are invisible or missing.
   Each row has Border(bottom: BorderSide(color: AppTheme.border, width: 1)) in code
   (desktop_sheet_review_row.dart line 52). However AppTheme.border appears too light
   against the white card background, making the separators effectively invisible.

4. No edit icon on expense rows.
   The actions column (SizedBox width 88) only contains approve (check) and decline
   (close) icons. The row is tappable (onTap navigates to expense detail) but there
   is no visible edit/eye icon to indicate it. Managers do not know the row is
   clickable.

## Reproduce Steps

1. Log in as a manager on a wide desktop screen.
2. Open any sheet in WaitingForApproval.
   -- Observe: content is constrained to ~720px; wide empty margins on both sides
      (issue 1).
   -- Observe: Date column content wraps for dates like "December 12th 2025" (issue 2).
   -- Observe: no visible separator lines between expense rows (issue 3).
   -- Observe: no edit or eye icon in the actions column; row clickability is hidden
      (issue 4).

## Suggested Solution Approach

1. Pass a larger maxWidth to ConstrainedContent on the sheet review screen (e.g. 1100px),
   or introduce a wider layout variant for manager pages.

2. Increase Date flex from 16 to 22-24 in both desktop_sheet_review_table.dart (header)
   and desktop_sheet_review_row.dart (row). Reduce Merchant or Category flex to compensate.

3. Use a slightly darker border color for table row separators, or use a dedicated
   AppTheme token that has sufficient contrast on white backgrounds.

4. Add an edit/eye icon as a third action in the actions column. Widen the actions
   SizedBox from 88px to ~120px to fit three icons.

## Suggested Fix

Issue 1 -- lib/screens/sheet_review_screen.dart:
  ConstrainedContent(maxWidth: 1100, child: ...)

Issue 2 -- lib/widgets/sheet_review/desktop_sheet_review_table.dart line 77 and
           lib/widgets/sheet_review/desktop_sheet_review_row.dart line 59:
  Change flex: 16 to flex: 22 for Date.
  Reduce Merchant flex: 24 to flex: 18.

Issue 3 -- lib/widgets/sheet_review/desktop_sheet_review_row.dart line 54:
  Replace AppTheme.border with a slightly darker color or a new AppTheme.tableBorder
  token.

Issue 4 -- lib/widgets/sheet_review/desktop_sheet_review_row.dart line 116:
  Add before the approve icon:
    ActionIconButton(icon: Icons.edit_outlined, tooltip: l10n.view, onPressed: onTap)
  Widen SizedBox from width: 88 to width: 120.
  Apply matching change to the header SizedBox in desktop_sheet_review_table.dart line 85.
