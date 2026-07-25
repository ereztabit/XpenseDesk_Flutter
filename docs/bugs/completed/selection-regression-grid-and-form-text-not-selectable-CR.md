# CR — Selection regression fix (scoped SelectableScope)

Reviewed change: restore text selection lost when the app-wide SelectionArea
was removed. One new shared widget (`lib/widgets/selectable_scope.dart`)
wrapping `SelectionArea`, applied at table/list-body level in 12 widgets plus
one `SelectableText` conversion. No app-wide wrapper reintroduced.

## TL;DR

Change is clean against all six rules. The new code adds no strings, no
amounts, no layout, and no logic — it only inserts a wrapper widget at
existing composition points. Three touched files exceed 200 lines and one
carries hardcoded English captions, but all of those violations pre-date this
change and are untouched by it; flagged below as out-of-scope follow-ups.

## 1. File-size audit

| File | Lines | Verdict |
|---|---|---|
| widgets/selectable_scope.dart (new) | 23 | OK |
| widgets/sticky_report_table.dart | 117 | OK |
| widgets/section_table.dart | 273 | pre-existing >200 (was ~280 before) |
| widgets/payments/desktop_payments_table.dart | 165 | OK |
| widgets/payments/mobile_payments_table.dart | 159 | OK |
| widgets/employee_dashboard/desktop_sheet_expense_table.dart | 62 | OK |
| widgets/employee_dashboard/mobile_sheet_expense_list.dart | 47 | OK |
| widgets/manager_dashboard/desktop_sheet_bucket_table.dart | 48 | OK |
| widgets/manager_dashboard/mobile_sheet_bucket_list.dart | 42 | OK |
| widgets/sheet_review/desktop_sheet_review_table.dart | 115 | OK |
| widgets/sheet_review/mobile_sheet_review_compact_list.dart | 50 | OK |
| widgets/analysis/master_table.dart | 155 | OK |
| widgets/analysis/pivot_table.dart | 251 | pre-existing >200 |
| widgets/users/user_list_card.dart | 480 | pre-existing >200 |
| widgets/profile/profile_identity_card.dart | 96 | OK |

## 2. Embedded private classes

None added. Pre-existing `_BodyRow` in section_table.dart is the state pair
pattern's allowed neighbor (row renderer ~40 lines) and untouched.

## 3. Inline logic

None added — the change is purely compositional (wrapper insertion).

## 4. Currencies & captions audit

Required caption grep on all 15 touched files returned **zero matches**
(exit 1, no output). Currency grep also zero. No new strings of any kind were
added by this change.

Pre-existing (out of scope, not introduced here): `user_list_card.dart`
`_buildEmptyState` has four hardcoded English captions built via ternaries
('No users found', 'No users match your search', 'Invite users to get
started', 'Try a different search term') — the grep misses them because they
are not direct `Text('...')` literals. Should be filed/fixed separately.

## 5. Flutter hygiene

Grep for `withOpacity`, `EdgeInsets.only(left/right)`, `TextAlign.left/right`,
`arrow_back_ios`, hardcoded currency symbols: **zero matches** on touched
files. `flutter analyze`: only the 9 known pre-existing info lints (tracked in
docs/bugs/flutter-analyze-info-lints-cleanup.md). `flutter build web`: clean.

## 6. Responsive overflow risk

None — no Row/flex/sizing changes. `SelectionArea` is a behavioral wrapper
with no intrinsic size effect. RTL unaffected (no directional properties
added).

## 7. Recommended fix plan

Nothing blocking. Follow-ups (separate items, not this change):

1. (should-fix, pre-existing) Localize the four hardcoded empty-state captions
   in `user_list_card.dart`.
2. (nit, pre-existing) `user_list_card.dart` at 480 lines — the dialog/handler
   bulk could move to a `users_actions` service/util per Rule 2.

## Runtime verification checklist (user, in dev)

- [ ] Payments report: drag-select and copy cell text (desktop + mobile).
- [ ] Profile: select/copy the read-only email.
- [ ] User Management: select/copy an email from the list.
- [ ] Manager dashboard buckets + Sheet Review: row tap still opens the sheet
      (rows are fully tappable InkWells under the new scope).
- [ ] Crash scenario: /manager/company-config — open dropdowns, trigger
      provider-driven rebuilds, resize the window; no SelectableRegion red
      screen.
