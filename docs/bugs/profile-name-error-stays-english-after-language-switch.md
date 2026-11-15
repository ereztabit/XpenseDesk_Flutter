# Bug: Profile "Name is required" stays in English after switching to Hebrew

> **Status: new**

Found in the manual QA dry run (2026-11-15, lane A - manager, desktop) on the
XpenseDesk Demo Company.

## Problem

On the profile screen, an inline validation error shown in English does not
change language when the user switches the UI to Hebrew. The Name field keeps
"Name is required" in English on an otherwise Hebrew, RTL screen, while the
phone error next to it does switch to Hebrew. The page looks half-translated.

## Reproduce Steps

1. Sign in (or connect from the admin panel) as any user, UI language English.
2. Open the profile (`/manager/profile` or `/employee/profile`).
3. Clear the Name field - "Name is required" appears.
4. Type `123` in Mobile phone and click elsewhere - "A mobile number starts with 05" appears.
5. Switch the UI language to Hebrew from the header language switcher.
   -- Expected: both errors re-render in Hebrew ("שם הוא שדה חובה" for the name).
   -- Actual: the phone error is Hebrew; the name error stays "Name is required".

## Suggested Solution Approach

Any error currently on screen should follow the UI language the moment it
changes, the same way the phone error already does.

## Suggested Fix

The name error comes from the `TextFormField` validator
(`lib/utils/profile_name_utils.dart` returns `l10n.nameRequired`). The `Form`
stores the validator's result string from the last validation, so it keeps the
English text until the field validates again. The phone error is held in state
(`_phoneError` in `lib/widgets/profile/profile_editor.dart`) and rebuilt, which
is why it follows the locale. The fix is to re-run validation when the locale
changes, for example `_formKey.currentState?.validate()` from
`didChangeDependencies` when the form has already shown errors. The other
option is to keep the name error as state, as the phone error is. Check whether
the government ID error (`l10n.govIdInvalidFormat`, also a validator) has the
same issue. The same pattern likely affects other forms that use `validator:`.
