# Bug: Admin feature switch thumb turns blue on hover

> **Status: in progress**

## Problem

On the platform admin's company Configuration tab, hovering an "on" switch
(Bulk receipt upload, Petty Cash module, Travel module) turns its white thumb
dark blue, the same colour as the track. The switch then looks like a solid
blue pill with no thumb, so it is unclear whether it is on. Found 2026-11-16
while QA-ing FS-1011 (PC-0); it affects every row of the Features card, the old
bulk upload row included.

## Reproduce Steps

1. Sign in as the platform admin, open any company -> Configuration.
2. Make sure a switch is on (Bulk receipt upload is on by default).
3. Hover the mouse over that switch.
   -- Expected: the white thumb stays visible on the purple track.
   -- Actual: the thumb turns blue and disappears into the track.

## Suggested Solution Approach

Every switch in the app looks the same in every state - on, off, hover,
disabled.

## Suggested Fix

`AdminFeatureToggleRow` (`lib/widgets/admin/admin_feature_toggle_row.dart`)
uses a bare Material `Switch` with only `activeTrackColor`, so the hovered
thumb falls back to the Material default colour. The same defect was fixed in
FS-1010 for the Modules tab by `ModuleSwitch`
(`lib/widgets/company_modules/module_switch.dart`), which sets explicit
`WidgetStateProperty` thumb and track colours for hover and disabled. Reuse
`ModuleSwitch` in the admin row (it also has the busy spinner), or move it to
`lib/widgets/` as the shared switch and add it to the CLAUDE.md shared-widget
table.

## Fix

`AdminFeatureToggleRow` now renders `ModuleSwitch` (reused in place, not moved).
Also fixes the FS-1011 review finding that, while one flag saves, the other
switches looked live but ignored clicks: the body now passes `onChanged: null`
to them, so `ModuleSwitch` shows them disabled.

## Manual QA

### Run 1 - 2026-11-16
- Branch / commit: feature/admin-switch-hover @ uncommitted
- QA company: XpenseDesk Demo Company (dev); platform admin platformadmin@xpensedesk.com (direct sign-in)
- Coverage: admin Configuration tab, desktop 1440 (EN + HE) and mobile 375 (HE). Hover on an "on" switch in EN and HE; Petty Cash turn-on and turn-off confirms with the save delayed 5s in the browser (XHR patch), clicking Travel and hovering Bulk upload while it saved; RTL thumb position.
- Not covered: manager/employee lanes - the change is admin-only.
- Data left: Demo company back to Petty Cash off, Travel off, bulk upload on.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| - | Admin, desktop + mobile | EN/HE | Configuration | - | Hover keeps the white thumb; during a save the saving row spins and the other two show disabled and ignore clicks | Pass |

Result: 0 findings.
