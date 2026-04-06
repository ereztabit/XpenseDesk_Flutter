# AppButton Migration Spec

**Goal:** Replace all raw Flutter button widgets across the app with the `AppButton` widget
(`lib/widgets/app_button.dart`) so styling, hover behavior, loading states, and accessibility
are consistent across the product.

**Rule going forward:** No screen or widget may use `ElevatedButton`, `FilledButton`,
`OutlinedButton`, or `TextButton` directly. All action buttons go through `AppButton`.

---

## Quick Reference — Replace or Skip?

### ✅ Replace with AppButton

| Location | Button | AppButton variant |
|----------|--------|-------------------|
| `login_screen.dart` | Continue with email | `primary` |
| `login_screen.dart` | Create account link | `ghost` |
| `login_callback_screen.dart` | Back to Login | `normal` |
| `profile_screen.dart` | Back to Dashboard | `ghost` |
| `profile_screen.dart` | Save Changes | `primary` |
| `new_expense_screen.dart` | Download receipt PDF | `ghost` |
| `new_expense_screen.dart` | Replace uploaded file | `ghost` |
| `new_expense_screen.dart` | Submit expense | `success` |
| `new_expense_screen.dart` | Back to Dashboard | `ghost` |
| `new_expense_screen.dart` | Replace file (preview bar) | `normal` + `size: small` |
| `new_expense_screen.dart` | Continue / Analyze | `success` |
| `employee_expense_detail_screen.dart` | Toggle modify/undo AI | `ghost` |
| `employee_expense_detail_screen.dart` | Enable editing mode | `ghost` |
| `employee_expense_detail_screen.dart` | Approve (manager) | `success` |
| `employee_expense_detail_screen.dart` | Decline (manager) | `destructive` |
| `employee_expense_detail_screen.dart` | Save expense details | `primary` |
| `employee_expense_detail_screen.dart` | Discard edits | `normal` |
| `employee_expense_detail_screen.dart` | Back to Dashboard (2×) | `ghost` |
| `employee_expense_detail_screen.dart` | Retry load | `normal` |
| `receipt_analyzer_screen.dart` | Pick image/file | `normal` |
| `receipt_analyzer_screen.dart` | Analyze receipt | `primary` |
| `company_config_screen.dart` | Back to Dashboard | `ghost` |
| `company_config_screen.dart` | Refresh billing data | `ghost` |
| `company_config_screen.dart` | Retry error state | `normal` |
| `cycle_expenses_report_screen.dart` | Apply Filters | `primary` + `isFullWidth` |
| `cycle_expenses_report_screen.dart` | Export to Excel | `normal` |
| `expenses_analysis_screen.dart` | Clear All filters | `ghost` |
| `expenses_analysis_screen.dart` | Run Report | `primary` + `isFullWidth` |
| `user_dashboard_screen.dart` | New Expense | `primary` |
| `users_screen.dart` | Back to Dashboard | `ghost` |
| `users_screen.dart` | Invite Users (2×) | `primary` |
| `employee_onboarding_screen.dart` | Submit onboarding | `primary` |
| `onboarding_screen.dart` | Back (step nav) | `normal` |
| `onboarding_screen.dart` | Next / Finish | `primary` |
| `onboarding/personal_details_step.dart` | Continue | `primary` |
| `onboarding/otp_verification_step.dart` | Verify OTP | `primary` |
| `onboarding/otp_verification_step.dart` | Start Over | `ghost` |
| `onboarding/company_details_step.dart` | Back | `normal` |
| `onboarding/company_details_step.dart` | Continue | `primary` |
| `users/user_list_card.dart` | Cancel dialogs (3×) | `ghost` |
| `users/user_list_card.dart` | Confirm role change | `primary` |
| `users/user_list_card.dart` | Delete / Disable User (2×) | `destructive` |
| `users/invite_users_dialog.dart` | Cancel | `ghost` |
| `users/invite_users_dialog.dart` | Send Invites | `primary` |
| `billing_current_plan_card.dart` | Cancel Scheduled Change | `ghost` + `size: small` |
| `billing_current_plan_card.dart` | Retry billing error | `normal` |
| `form_behavior_mixin.dart` | Keep Editing | `ghost` |
| `form_behavior_mixin.dart` | Leave Without Saving | `destructive` |
| `step_guard_mixin.dart` | Keep Editing | `ghost` |
| `step_guard_mixin.dart` | Leave Without Saving | `destructive` |
| `multi_select_filter.dart` | Select All / Clear / Done (3×) | `ghost` / `primary` |
| `category/category_selector.dart` | Select All / Clear (2×) | `ghost` |

### ❌ Do Not Replace

| Location | Button | Reason |
|----------|--------|--------|
| `login_screen.dart` DEV buttons (2×) | Auto-login admin/user | Dev-only debug buttons; intentional orange colour |
| `onboarding/otp_verification_step.dart` | Resend OTP | Cooldown colour-swap state; not modelled by `AppButton` |
| `onboarding/otp_verification_step.dart` | "Wrong email?" | Inline underlined text link, not a button |
| `multi_select_filter.dart` | Filter trigger chip | Compact outline chip (36 px) opening a popup; revisit after `size: small` lands |
| `search_button.dart` | Search CTA | Standalone widget — rewrite the widget itself using `AppButton(size: small)` after enhancement lands |
| `app_footer.dart` links (4×) | Privacy Policy / Terms | Navigation anchor links, no action semantics |

---

## Current AppButton Capabilities

| Property | Value |
|----------|-------|
| `label` | required String |
| `onPressed` | `VoidCallback?` — null disables the button |
| `variant` | `primary`, `destructive`, `success`, `normal`, `ghost` |
| `icon` | optional leading `IconData` |
| `isLoading` | replaces child with white spinner, nullifies `onPressed` |
| Shape | `BorderRadius.circular(12)` always |
| Padding | `horizontal 24, vertical 14` always |
| Hover | defined per variant |
| Cursor | always `SystemMouseCursors.click` |

---

## Required Enhancements (before migration can be complete)

The following gaps prevent some buttons from being migrated without first extending `AppButton`.

### 1. `size` parameter — `AppButtonSize.regular` / `AppButtonSize.small`

Many buttons in the app use compact sizing (36 px or 30 px height, less horizontal padding).
The current fixed `h24 v14` padding produces oversized buttons when used inline or inside
toolbars/filter bars. A `size` parameter is needed.

Suggested values:

| Size | Padding | Font size |
|------|---------|-----------|
| `regular` (default) | `h24 v14` | inherited (theme) |
| `small` | `h12 v8` | 13 sp |

Affects:
- `billing_current_plan_card.dart` — "Cancel Scheduled Change" compact button
- `search_button.dart` — fixed 40 px height search CTA
- `multi_select_filter.dart` — filter trigger button (36 px height)
- `widgets/users/invite_users_dialog.dart` — dialog buttons fit better small

### 2. `isFullWidth` parameter — `bool` (default `false`)

Several buttons stretch to `double.infinity`. Currently callers wrap them in
`SizedBox(width: double.infinity)`. An `isFullWidth` parameter on `AppButton` keeps call
sites clean and makes intent explicit. Internally it just wraps the button in
`SizedBox(width: double.infinity)`.

Affects:
- `cycle_expenses_report_screen.dart` — Apply Filters button
- `expenses_analysis_screen.dart` — Run Report button
- `screens/users_screen.dart` — Invite Users (narrow layout)

### 3. `isLoading` spinner color

Currently the in-progress spinner is always white (`Colors.white`). This is invisible on the
**`ghost`** and **`normal`** variants (light / transparent backgrounds). Fix: resolve spinner
color by variant — white for `primary`, `destructive`, `success`; `AppTheme.foreground` for
`ghost`, `normal`.

---

## Migration List

### Notation

- `→ AppButton(variant: X)` means a straightforward drop-in replacement
- `→ AppButton(variant: X, size: small)` requires the size enhancement above
- `⚠️` marks a defect (hardcoded string or other violation found during audit)

---

### screens/login_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~194 | `ElevatedButton` | Continue with email | `→ AppButton(variant: primary)` |
| ~206 | `OutlinedButton` | DEV: auto-login admin | **Exclude — DEV-only, orange colour is intentional debug visual** |
| ~229 | `OutlinedButton` | DEV: auto-login user | **Exclude — DEV-only** |
| ~261 | `TextButton` | Create account (navigate) | `→ AppButton(variant: ghost)` |

---

### screens/profile_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~151 | `TextButton.icon` | Back to Dashboard | `→ AppButton(variant: ghost, icon: Icons.arrow_back)` |
| ~382 | `FilledButton` | Save Changes | `→ AppButton(variant: primary, isLoading: _isLoading)` |

---

### screens/new_expense_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~853 | `TextButton.icon` | Download receipt PDF | `→ AppButton(variant: ghost, icon: Icons.download)` |
| ~858 | `TextButton.icon` | Replace uploaded file | `→ AppButton(variant: ghost, icon: Icons.swap_horiz)` |
| ~1488 | `ElevatedButton` | Submit expense | `→ AppButton(variant: success, isLoading: _isSubmitting)` — dynamic `bg: success` collapsed into variant |
| ~1613 | `TextButton.icon` | Back to Dashboard | `→ AppButton(variant: ghost, icon: Icons.arrow_back)` |
| ~1700 | `OutlinedButton` | Replace file (preview bar) | `→ AppButton(variant: normal, size: small)` |
| ~1757 | `ElevatedButton` | Continue / Analyze | `→ AppButton(variant: success)` — disabled via `onPressed: _fileBytes != null ? _analyze : null` |

---

### screens/employee_expense_detail_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~492 | `TextButton.icon` | Toggle modify / undo AI details | `→ AppButton(variant: ghost, icon: ...)` |
| ~620 | `TextButton.icon` | Enable editing mode | `→ AppButton(variant: ghost, icon: Icons.edit, size: small)` |
| ~669 | `FilledButton.icon` | Approve (manager) | `→ AppButton(variant: success, icon: Icons.check, isLoading: _isSaving)` |
| ~679 | `FilledButton.icon` | Decline (manager) | `→ AppButton(variant: destructive, icon: Icons.close)` — disabled via `onPressed: _isSaving ? null : _decline` |
| ~737 | `FilledButton.icon` | Save expense details | `→ AppButton(variant: primary, icon: Icons.save, isLoading: _isSaving)` |
| ~748 | `OutlinedButton` | Discard edits | `→ AppButton(variant: normal)` — disabled via `onPressed: _isSaving ? null : pop` |
| ~785 | `OutlinedButton` | Back to Dashboard (not-found state) | `→ AppButton(variant: ghost)` |
| ~799 | `OutlinedButton` | Retry load (error state) | `→ AppButton(variant: normal)` |
| ~815 | `TextButton.icon` | Back to Dashboard | `→ AppButton(variant: ghost, icon: Icons.arrow_back)` |

---

### screens/receipt_analyzer_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~101 | `ElevatedButton.icon` | Pick image/file | `→ AppButton(variant: normal, icon: Icons.upload_file)` |
| ~115 | `ElevatedButton` | Analyze receipt | `→ AppButton(variant: primary, isLoading: _isLoading)` |

---

### screens/company_config_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~197 | `TextButton.icon` | Back to Dashboard | `→ AppButton(variant: ghost, icon: Icons.arrow_back)` |
| ~541 | `TextButton.icon` | Refresh billing data | `→ AppButton(variant: ghost, icon: Icons.refresh)` |
| ~735 | `OutlinedButton.icon` | Retry (error state) | `→ AppButton(variant: normal, icon: Icons.refresh)` ⚠️ also fix hardcoded `'Retry'` → `l10n.retry` |

---

### screens/cycle_expenses_report_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~405 | `FilledButton` | Apply Filters | `→ AppButton(variant: primary, isFullWidth: true)` |
| ~696 | `FilledButton.icon` | Export to Excel | `→ AppButton(variant: normal, icon: Icons.download, isLoading: _isExporting)` |

---

### screens/expenses_analysis_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~241 | `TextButton` | Clear All filters | `→ AppButton(variant: ghost)` |
| ~252 | `FilledButton.icon` | Run Report | `→ AppButton(variant: primary, icon: Icons.bar_chart, isFullWidth: true)` |

---

### screens/user_dashboard_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~301 | `FilledButton.icon` | New Expense | `→ AppButton(variant: primary, icon: Icons.add)` |

---

### screens/users_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~35 | `TextButton.icon` | Back to Dashboard | `→ AppButton(variant: ghost, icon: Icons.arrow_back)` |
| ~68 | `FilledButton.icon` | Invite Users (narrow, full-width) | `→ AppButton(variant: primary, icon: Icons.person_add, isFullWidth: true)` |
| ~100 | `FilledButton.icon` | Invite Users (desktop) | `→ AppButton(variant: primary, icon: Icons.person_add)` |

---

### screens/login_callback_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~128 | `FilledButton` | Back to Login (error state) | `→ AppButton(variant: normal)` ⚠️ also fix hardcoded `'Back to Login'` → `l10n.backToLogin` |

---

### screens/employee_onboarding_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~384 | `ElevatedButton` | Submit onboarding form | `→ AppButton(variant: primary, isLoading: _isSubmitting)` — `primaryDark` background collapses to `primary` variant |

---

### screens/onboarding/onboarding_screen.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~228 | `OutlinedButton` | Back (step navigator) | `→ AppButton(variant: normal)` |
| ~248 | `ElevatedButton` | Next / Finish (step navigator) | `→ AppButton(variant: primary)` |

---

### screens/onboarding/steps/personal_details_step.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~192 | `ElevatedButton` | Continue | `→ AppButton(variant: primary, isLoading: _isCheckingEmail)` |

---

### screens/onboarding/steps/otp_verification_step.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~362 | `TextButton` | "Wrong email?" link | **Exclude — inline text link with underline decoration; not a standard button** |
| ~420 | `TextButton` | Resend OTP | **Exclude — unusual cooldown colour-swap state not modelled by `AppButton`; keep raw with a note** |
| ~435 | `ElevatedButton` | Verify OTP | `→ AppButton(variant: primary, isLoading: _isSubmitting)` |
| ~618 | `ElevatedButton` | Start Over (expired state) | `→ AppButton(variant: ghost)` |

---

### screens/onboarding/steps/company_details_step.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~472 | `OutlinedButton` | Back | `→ AppButton(variant: normal)` — `onPressed: _isSubmitting ? null : _handleBack` |
| ~492 | `ElevatedButton` | Continue | `→ AppButton(variant: primary, isLoading: _isSubmitting)` |

---

### widgets/users/user_list_card.dart (dialogs)

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~365 | `TextButton` | Cancel role change dialog | `→ AppButton(variant: ghost)` |
| ~368 | `FilledButton` | Confirm role change | `→ AppButton(variant: primary)` |
| ~404 | `TextButton` | Cancel delete dialog | `→ AppButton(variant: ghost)` |
| ~407 | `FilledButton` | Delete User | `→ AppButton(variant: destructive)` |
| ~460 | `TextButton` | Cancel disable dialog | `→ AppButton(variant: ghost)` |
| ~463 | `FilledButton` | Disable User | `→ AppButton(variant: destructive)` |

---

### widgets/users/invite_users_dialog.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~152 | `OutlinedButton` | Cancel invite | `→ AppButton(variant: ghost)` — `onPressed: _isLoading ? null : pop` |
| ~158 | `FilledButton` | Send Invites | `→ AppButton(variant: primary, isLoading: _isLoading)` |

---

### widgets/company_config/billing_current_plan_card.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~508 | `OutlinedButton` | Cancel Scheduled Plan Change | `→ AppButton(variant: ghost, size: small, isLoading: _cancelling)` — needs size enhancement |
| ~584 | `OutlinedButton` | Retry billing error | `→ AppButton(variant: normal)` |

---

### widgets/form_behavior_mixin.dart (unsaved-changes dialog)

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~45 | `TextButton` | Keep Editing | `→ AppButton(variant: ghost)` |
| ~49 | `TextButton` | Leave Without Saving | `→ AppButton(variant: destructive)` — currently uses `foregroundColor: Colors.red` |

---

### widgets/step_guard_mixin.dart (step-guard dialog)

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~33 | `TextButton` | Keep Editing | `→ AppButton(variant: ghost)` |
| ~37 | `TextButton` | Leave Without Saving | `→ AppButton(variant: destructive)` |

---

### widgets/multi_select_filter.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~52 | `TextButton` | Select All (dialog) | `→ AppButton(variant: ghost, size: small)` |
| ~55 | `TextButton` | Clear (dialog) | `→ AppButton(variant: ghost, size: small)` |
| ~112 | `TextButton` | Done (close dialog) | `→ AppButton(variant: primary)` |
| ~128 | `OutlinedButton` | Filter trigger (opens popup) | **Exclude — low-profile outline chip with 36 px height and popup open behaviour. Keep raw with intentional style override. Revisit when `size: small` lands.** |

---

### widgets/category/category_selector.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~68 | `TextButton` | Select All (menu header) | `→ AppButton(variant: ghost, size: small)` |
| ~74 | `TextButton` | Clear (menu header) | `→ AppButton(variant: ghost, size: small)` |

---

### widgets/search_button.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~20 | `FilledButton` | Search CTA | **Exclude for now — `SearchButton` is a standalone widget with a fixed 40 px height; easier to rewrite the widget itself to use `AppButton(size: small)` after the enhancement lands** |

---

### widgets/app_footer.dart

| Line | Current | Purpose | Migration |
|------|---------|---------|-----------|
| ~38 | `TextButton` | Privacy Policy (mobile) | **Exclude — navigation anchor links, not action buttons. No loading/disabled states needed.** |
| ~44 | `TextButton` | Terms of Service (mobile) | **Exclude — same reason** |
| ~76 | `TextButton` | Privacy Policy (desktop) | **Exclude — same reason** |
| ~84 | `TextButton` | Terms of Service (desktop) | **Exclude — same reason** |

---

## Explicit Exclusions Summary

| Location | Reason for exclusion |
|----------|---------------------|
| `login_screen.dart` DEV buttons (~206, ~229) | Development-only; intentional orange colour is a debug visual |
| OTP "Wrong email?" link (~362) | Inline text link with underline — not a button |
| OTP Resend button (~420) | Unusual cooldown colour-swap state `AppButton` doesn't model |
| `multi_select_filter.dart` trigger (~128) | Compact outline chip opening a popup; revisit post–`size: small` |
| `search_button.dart` (~20) | Standalone widget — rewrite the widget itself after `size: small` lands |
| `app_footer.dart` links (all 4) | Navigation links, not action buttons |

---

## Defects Found During Audit (fix during migration)

1. **`screens/login_callback_screen.dart` ~128** — `FilledButton` uses `const Text('Back to Login')` — hardcoded English string. Fix: add `backToLogin` ARB key and use `l10n.backToLogin`.

2. **`screens/company_config_screen.dart` ~735** — `OutlinedButton.icon` uses `const Text('Retry')` — hardcoded English string. Fix: add `retry` ARB key (if not already present) and use `l10n.retry`.

---

## Implementation Order

Suggested sequence to reduce risk and catch issues early:

1. **Add enhancements first:**
   - `size: AppButtonSize` parameter (`regular` default, `small`)
   - `isFullWidth: bool` parameter
   - Fix `isLoading` spinner colour per variant

2. **Migrate screens in this order** (highest traffic → lowest):
   - `user_dashboard_screen.dart` (simple, 1 button)
   - `profile_screen.dart` (2 buttons)
   - `users_screen.dart` (3 buttons)
   - `expenses_analysis_screen.dart`
   - `cycle_expenses_report_screen.dart`
   - `employee_expense_detail_screen.dart` (most buttons, do last in this group)
   - `new_expense_screen.dart`
   - Onboarding screens (personal → OTP → company → onboarding_screen)
   - `login_screen.dart`, `employee_onboarding_screen.dart`
   - `company_config_screen.dart`, `receipt_analyzer_screen.dart`, `login_callback_screen.dart`

3. **Migrate widgets:**
   - `form_behavior_mixin.dart`, `step_guard_mixin.dart`
   - `widgets/users/user_list_card.dart`, `widgets/users/invite_users_dialog.dart`
   - `widgets/company_config/billing_current_plan_card.dart`
   - `widgets/multi_select_filter.dart`, `widgets/category/category_selector.dart`

4. **Build + verify after each file.** Run `flutter build web` and check `get_errors` before moving to the next file.
