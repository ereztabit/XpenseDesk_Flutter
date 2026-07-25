# Coupon Lockout UX — Behavioral Specification

## Context

The server now enforces a hard lockout after 5 consecutive failed coupon validation
attempts per company (`429 CouponLocked`). When a company is locked, every validate
call -- including a valid coupon code -- returns:

```json
{
  "success": false,
  "errorCode": "CouponLocked",
  "message": "Too many failed coupon attempts. Please try again later."
}
```

HTTP status: `429 Too Many Requests`.

The `CouponSection` widget (`lib/widgets/plan_selection/coupon_section.dart`) already
has a client-side 3-attempt block (`_blocked = true`) that silently collapses the
widget. The server lock is a different concern: it must be surfaced visibly with a
clear message so the user understands why the field is disabled, not hidden
with no explanation.

---

## Affected File

`lib/widgets/plan_selection/coupon_section.dart`

The widget is used in:
- `lib/screens/onboarding/steps/plan_selection_step.dart`
- `lib/screens/complete_payment_screen.dart`

No other files need changes unless the service layer needs a typed exception (see
Step 1 below).

---

## Service Layer Contract

`AuthService.validateCoupon(code)` currently throws a generic `Exception` on any
non-OK response. It needs to surface the lockout distinctly so the widget can react
differently from a plain invalid-coupon response.

Check how `validateCoupon` in `lib/services/auth_service.dart` reads the response.
If it already exposes `errorCode` on failure, catch it in the widget. If not, add a
typed exception:

```dart
class CouponLockedException implements Exception {}
```

Throw it when `errorCode == 'CouponLocked'` (status 429). The widget catches it
separately from the plain-invalid path.

---

## New State: Server Lockout

Add a `_serverLocked` bool to `_CouponSectionState` (separate from the existing
`_blocked` client-side flag). Set it to `true` when `CouponLockedException` is
caught in `_apply()`.

### When `_serverLocked == true`

The coupon section stays **expanded and visible** -- do not collapse or hide.

Layout (top to bottom):

1. The label row (`l10n.haveCoupon`) -- unchanged.
2. The input row with:
   - `TextField` in a disabled state (`enabled: false`).
   - The "Apply" button replaced by nothing (or hidden) -- no action is possible.
3. A lockout error row below the input:
   - Icon: `Icons.lock_outline`, size 16, color `AppTheme.destructive`.
   - Text: `l10n.couponLockedError` (see L10n section below).
   - Style: `fontSize: 14`, `color: AppTheme.destructive`.
   - Layout: `Row` with `MainAxisAlignment.start`, `gap: 6` between icon and text.

The existing `_blocked` (client-side) path keeps its current behavior (collapse
silently). Do not merge the two states -- they have different UX intent.

---

## L10n Keys to Add

Add to `lib/l10n/app_en.arb`:
```json
"couponLockedError": "Too many failed attempts. Please contact support to unlock."
```

Add to `lib/l10n/app_he.arb`:
```json
"couponLockedError": "יותר מדי ניסיונות כושלים. אנא פנה לתמיכה לביטול הנעילה."
```

---

## Implementation Steps

Follow the project rule: build after every step, zero errors before moving on.

### Step 1 -- Service layer

Open `lib/services/auth_service.dart`. Find `validateCoupon`.

If the method currently swallows all errors into a generic result, update it to:
- Detect `errorCode == 'CouponLocked'` on a 429 response.
- Throw `CouponLockedException()` instead of returning `isValid: false`.

If the method already throws a typed exception or exposes `errorCode`, skip this
step and catch accordingly in the widget.

Build. Zero errors.

### Step 2 -- Add ARB keys

Add `couponLockedError` to both `app_en.arb` and `app_he.arb` (see L10n section).
Run `flutter pub get`.

Build. Zero errors.

### Step 3 -- Widget state and catch

In `_CouponSectionState`:
- Add `bool _serverLocked = false;`
- In `_apply()`, add a `on CouponLockedException` catch before the generic
  `on Exception` catch:

  ```dart
  on CouponLockedException {
    if (!mounted) return;
    setState(() {
      _serverLocked = true;
      _isApplying = false;
    });
    widget.onCouponResult(null);
  }
  ```

Build. Zero errors.

### Step 4 -- Widget UI

In `build()`, add the `_serverLocked` branch. Insert it before the `_blocked`
check (or after -- both return early, order does not matter):

```dart
if (_serverLocked) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.haveCoupon,
          style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: false,
              decoration: InputDecoration(
                hintText: l10n.enterCouponCode,
                counterText: '',
                prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: AppTheme.destructive.withAlpha(80)),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppTheme.destructive),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.couponLockedError,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.destructive,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
```

Build. Zero errors.

### Step 5 -- Manual verification

Open the Plan Selection step (or Complete Payment screen). Enter five wrong coupon
codes in a row, hitting Apply each time. On the fifth failure, the server returns
`429 CouponLocked`. Confirm:

- [ ] The field stays visible but disabled (grayed out border).
- [ ] The lock icon + `couponLockedError` text appears below the field.
- [ ] The Apply button is gone.
- [ ] Typing in the field is not possible.
- [ ] The "Have a coupon?" label is visible at the top.
- [ ] RTL (Hebrew): icon and text are start-aligned correctly.

---

## Out of Scope

- The existing client-side 3-attempt block (`_blocked`) is left unchanged.
- No backend changes -- server-side lockout is already shipped and tested.
- No admin-release flow -- if a company is locked a developer deletes the row from
  `CompanyCouponLockout` directly in the DB.
- The `complete_payment_screen.dart` uses the same `CouponSection` widget, so it
  gets the fix for free -- no separate screen changes needed.
