# Bug: Admin feature switch thumb turns blue on hover

> **Status: new**

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
