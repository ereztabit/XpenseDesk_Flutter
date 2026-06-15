# Dead-Code Audit — 2026-06-15 (MVP end-of-cycle sweep)

End-to-end pass over the Flutter app for (1) zero-reference functions, (2) unused
config keys, (3) stale widgets. Method: `flutter analyze` for private dead code +
cross-file reference analysis (grep every public symbol across `lib/`, excluding
`generated/`, the declaring file, and comments).

**Result:** 15 files deleted, ~25 dead members removed. `flutter analyze` went from
16 → 8 issues (the 8 remaining are pre-existing style lints, see bottom). `flutter
build web` is green. No behaviour change.

---

## ✅ Removed — stale files (15)

The expense-list family widgets are leftovers from **before** the Expense Sheets
transformation (stories 01–03); the new UI lives in `widgets/employee_dashboard/`,
`widgets/sheet_review/`, and `widgets/expenses/` (card + table variants still in use).

| File | Why |
|------|-----|
| `models/user.dart` (`User`, `UserRole`) | Superseded by `UserInfo` / `UserDetails` / `UserListItem`; never imported |
| `models/expense_currency.dart` (`ExpenseCurrency`) | Only consumer was the deleted `expense_form.dart` → orphaned |
| `screens/receipt_analyzer_screen.dart` | Unrouted; receipt scan now lives in the new-expense flow (`ExpenseCreateImagePanel`) |
| `screens/tranzila_poc_screen.dart` | Dev POC, unrouted |
| `widgets/cycle/cycle_full_card.dart` | Unused; cycle UI uses `cycle_compact_badge` / `cycle_selector` |
| `widgets/expenses/desktop_expense_section.dart` | Pre-sheets expense list |
| `widgets/expenses/desktop_expense_table.dart` | Pre-sheets expense list |
| `widgets/expenses/expenses_empty_state.dart` | Pre-sheets expense list |
| `widgets/expenses/expense_form.dart` | Pre-sheets; new-expense screen has its own inline form |
| `widgets/expenses/expense_status_toggle.dart` | Pre-sheets expense list |
| `widgets/expenses/mobile_expense_modal.dart` | Pre-sheets (all classes private, file unimported) |
| `widgets/expenses/receipt_analyzer_dialog.dart` | Superseded by in-flow scanning |
| `widgets/expenses/total_approved_badge.dart` | Pre-sheets expense list |
| `widgets/header/pending_payment_banner.dart` | Unused; banner work lives in `billing_alert_banner` |
| `widgets/multi_select_filter.dart` | Unused generic filter |

## ✅ Removed — dead public members / providers

| Location | Symbol |
|----------|--------|
| `providers/expense_provider.dart` | `expenseDetailProvider` (+ unused `ExpenseDetail` import) — detail screen calls `getExpenseById` directly |
| `services/expense_service.dart` | `EditApprovedExpenseOnDeclinedSheetException` — never thrown or caught |
| `models/expense_sheet_status.dart` | `SheetMode` enum — only self-referenced |
| `providers/locale_provider.dart` | `LocaleNotifier.toggleLocale()` |
| `providers/users_provider.dart` | `UserSearchNotifier.clear()` |
| `providers/payments_provider.dart` | `PaymentsFilterNotifier.reset()` |
| `providers/manager_dashboard_provider.dart` | `SelectedEmployeeFilterNotifier.clear()` |
| `providers/employee_dashboard_provider.dart` | `DismissedReturnedAlertKeyNotifier.clear()` |
| `utils/conversion_preview_controller.dart` | `isLoading` getter, `reset()` method |
| `models/user_list_item.dart` | `roleName`, `toJson`, `copyWith` |
| `models/user_info.dart` | `toJson` (only the session token is persisted, never UserInfo JSON) |
| `models/billing_transaction.dart` | `isFree` |
| `models/expense_sheet_detail.dart` | `status`, `expenseCount`, `totalAmount` getters (+ unused import) |
| `models/expense_sheet_list_item.dart` | `status` getter (+ unused import) |

## ✅ Removed — dead private fields / dead imports (from `flutter analyze`)

- `screens/onboarding/steps/plan_selection_step.dart` — `_messenger`, `_successMsg` (write-only success-toast remnants)
- `widgets/company_config/billing_current_plan_card.dart` — `_messenger`, `_successMsg` (same)
- `screens/new_expense_screen.dart` — unnecessary `dart:typed_data` import
- `widgets/category/category_selector.dart` — unnecessary `dart:ui` import
- `widgets/header/billing_alert_banner.dart` — unused `app_theme.dart` import

---

## Resolved (your call, 2026-06-15)

- **#1 — DELETED.** `CompletePaymentScreen` was an unreachable stub. Removed the
  screen + the `/complete-payment` route case + `AppRoutes.completePayment` constant.
  (`CouponSection`/`PlanCard` kept — they have other live consumers.)
- **#4 — FILED as a bug.** `docs/bugs/auth-service-email-regex-violates-validator-rule.md`.
- **#7 — DONE.** `SheetExpenseBuckets.approvable` → `_approvable`,
  `PaymentsSelectionUtils.totalAmountFor` → `_totalAmountFor`.
- **#2, #3, #5, #6 — left as-is** per your call (see below).

---

## ❓ Open questions — CLOSED

Task completed 2026-06-15. The remaining open questions (#2, #3, #5, #6) were
reviewed and **disregarded** by the owner — no action needed. Recorded below for
history only.

### 1. `CompletePaymentScreen` is an unreachable stub — RESOLVED (deleted, see above)

### 2. Unused `app:` config section
`app_config_dev.yaml` / `app_config_prod.yaml` both have an `app:` block
(`name`, `version`, `environment`) but `AppConfig` exposes **no getter** for any of them —
nothing reads them. **→ Remove the block, or wire `version`/`name` into an About/footer?**

### 3. `isBackendOnSameMachine: true` deploy path
`AppConfig.apiBaseUrl` supports a "same machine" mode using `backendScheme` /
`backendPort`, but both yamls ship `isBackendOnSameMachine: false` and neither sets
those two keys (code falls back to `https`/`7223`). The branch is dead in current
config. **→ Keep as a supported dev deploy mode, or drop it and simplify to `baseUrl`?**

### 4. `AuthService.isValidEmail` — regex, used only internally
Public method, called only inside `auth_service.dart` (pre-validation). It's a hand-rolled
regex, which **violates the repo rule** to always use the `email_validator` package.
**→ Replace with `EmailValidator` and make it private?** (behaviour change — left alone.)

### 5. `InvalidExpenseSheetStatusForListingException` — thrown, never caught
Thrown in `expense_service.dart` but no `on InvalidExpenseSheetStatusForListingException`
catch exists anywhere; it's purely defensive. **→ Keep, or wire a handler / fold into the
generic `ExpenseException`?** (Kept — it's reachable at runtime, not strictly dead.)

### 6. `context.isWide` — documented but zero references
`utils/responsive_utils.dart` exposes `isWide`, documented in CLAUDE.md as part of the
`isNarrow`/`isMobile`/`isWide`/`isDesktop` set, but nothing uses it. **→ Keep for API
symmetry, or remove and drop it from CLAUDE.md?** (Kept — it's documented public API.)

### 7. Public helpers that could be private (nits, low value)
- `utils/sheet_utils.dart` → `SheetExpenseBuckets.approvable` — used only by its own file's `approvableCount`/`approvableAmount`
- `utils/payments_utils.dart` → `PaymentsSelectionUtils.totalAmountFor` — used only by its own file's `totalAmountTextFor`

Both are referenced (not dead), just over-exposed. Could be `_`-prefixed.

---

## Context (not dead code, just noting)
`flutter analyze`'s remaining 8 issues are all pre-existing style lints, not dead code:
`use_null_aware_elements` (×2), deprecated `dart:html` in `tranzila_popup_service` and
`billing_payment_method_card` (these block wasm builds), `use_build_context_synchronously`,
`unnecessary_underscores` (×2), and the `_couponCode` warning from open question #1.
