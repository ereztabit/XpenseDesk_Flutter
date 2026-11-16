# FS-1010 - Lovable mock prompts

> Mission: FS-1010. Spec: company-modules-and-categories-spec.md (same folder).
> Target: app mock "Expense Desk" `0c5b063f-74a7-4490-b75e-746f4a712bde` - never the marketing project.

Small parts, one per Lovable round (LOVABLE.md §B4). Plan mode first for each.

## Round 1 - Modules tab + module page with settings

```
Scope: add a "Modules" tab to Company Configuration where a manager turns modules on/off and opens each module's page with its settings.
Files: src/pages/CompanyConfiguration.tsx (add a 4th tab "modules" next to general / billing / transactions, same ?tab= URL handling), src/context/UserContext.tsx (mock state), src/i18n/dictionaries.ts (en + he). New components under src/components/modules/ if needed.
Change:
- Mock state in UserContext: modules = [{ key: 'monthly' | 'pettyCash' | 'travel', enabled: boolean, settings }]. Initial: monthly on, pettyCash off, travel off. pettyCash.settings = { allowNegativeBalance: false }. Monthly and travel have no settings yet.
- Modules tab: three cards in this order - Monthly expenses (EN "Monthly expenses", HE "הוצאות חודשיות"), Petty Cash (EN "Petty Cash", HE "קופה קטנה"), Travel (EN "Travel abroad", HE "נסיעות לחו\"ל"). Each card: icon, name, one-line description, on/off switch, and a "Configure" button when on.
- Monthly: switch shows ON and is disabled, with a muted hint "Can't be turned off yet" / "לא ניתן לכבות כרגע".
- Rule: at least one module must stay on (enforce in the mock even though Monthly is locked).
- Turning Petty Cash or Travel ON: switch flips and the module page opens immediately.
- Turning a module OFF: AlertDialog confirm ("New items can't be created; existing records stay visible").
- Module page (inside the Modules tab, with a back link to the module list, not a new route): header with module name + on/off state, then a "Settings" card and an empty "Categories" card placeholder ("Categories - coming next round").
  - Petty Cash settings: one switch "Allow negative balance" / "לאפשר יתרה שלילית" with helper text "A petty cash sheet may spend more than its budget" / "קופה קטנה יכולה לחרוג מהתקציב שלה".
  - Monthly + Travel: "No settings yet" muted line.
- Dev panel: extend the existing page's dev tools (don't invent a new panel style) with a "Reset modules" action.
Constraints: Hebrew RTL - Latin/numbers as LTR islands, logical CSS properties only; gender-neutral Hebrew, no addressing the reader; AA contrast; check both languages and 375px + desktop. UI/UX only, shallow mock logic. No browser/Playwright runs or screenshots - a type check is enough.
Out of scope: categories editor (next round), any change to other tabs, other screens, routing, or existing specs. Do not refactor or rename anything else.
Do not publish.
```

## Round 2 - Categories editor (Monthly + Petty Cash)

Sent 2026-11-15 after round 1 (mock commit 58fc9b38).

```
Scope: replace the "Categories - coming next round" placeholder on the Monthly and Petty Cash module pages with a working categories editor. Travel keeps the placeholder (next round).
Files: src/components/modules/ModulePage.tsx (swap the placeholder card), new src/components/modules/CategoriesCard.tsx + a category add/edit dialog component in the same folder, src/context/UserContext.tsx (mock state), src/i18n/dictionaries.ts (en + he), public/modules-spec.md (append a Categories section).
Change:
- Mock state in UserContext: categories per module: { id, module, nameEn, nameHe, active, used } where `used` = "has expenses" (mock flag, no real link to expenses). Seed:
  - monthly (all used: true except Software): Travel / נסיעות, Food & meals / אוכל וארוחות, Supplies / ציוד, Software / תוכנה, Hotels / מלונות, Other / אחר.
  - pettyCash (all used: false): Office supplies / ציוד משרדי, Refreshments / כיבוד, Cleaning / ניקיון, Postage & delivery / דואר ומשלוחים, Small repairs / תיקונים קטנים, Other / אחר.
- Display name: the current UI language's name; if empty, fall back to the other language's name. List sorted alphabetically by the displayed name (locale compare in the current language).
- Each row: name, a muted secondary line with the other language's name, "Inactive" badge when inactive, and a row menu (DropdownMenu, kebab icon) with: Edit names, Deactivate / Reactivate, Delete.
  - Delete is shown only when used = false; confirm with AlertDialog "Delete category?" then remove.
  - When used = true, instead of Delete show a disabled item with hint "In use - can be deactivated" / "בשימוש - ניתן להשבית".
  - Inactive rows: muted text, sorted together with the rest (no separate section).
- "Add category" button above the list -> Dialog with two inputs: "Name in Hebrew" (dir rtl) and "Name in English" (dir ltr). Save enabled when at least one is filled. Inline error when the name already exists in this module (either language, case-insensitive): "A category with this name already exists" / "כבר קיימת קטגוריה בשם הזה". New categories: active, used: false.
- Edit names reuses the same dialog, prefilled.
- Empty state is not needed (seeded lists are never empty) but the list must not break if all are inactive.
- Dev panel (existing Modules dev tools): add "Mark all used" and "Mark all unused" for the open module, and make "Reset modules" also reset categories.
Constraints: Hebrew RTL - Latin/numbers as LTR islands, logical CSS properties only; gender-neutral Hebrew, no addressing the reader; AA contrast; check both languages and 375px + desktop (row menu reachable on mobile, 44px targets). UI/UX only, shallow mock logic. No browser/Playwright runs or screenshots - a type check is enough.
Out of scope: Travel categories and tax keys (next round), the expense form's category picker, any other screen or tab. Do not refactor or rename anything else.
Do not publish.
```

Follow-ups after round 2 (direct messages, no plan): Radix DirectionProvider
(RTL), Switch thumb via logical margin, single-line "HE / EN" names, inline
Edit + Delete icons (Delete deactivates when used; inactive rows show
Reactivate), turning a module on no longer opens its page.

## Round 3 - Travel categories with tax keys

```
Scope: give the Travel module page a working categories editor where every category carries a tax key, and the seven system categories are locked.
Files: src/context/UserContext.tsx (mock state), src/components/modules/ModulePage.tsx (Travel uses CategoriesCard instead of the placeholder), src/components/modules/CategoriesCard.tsx, src/components/modules/CategoryDialog.tsx, src/i18n/dictionaries.ts (en + he), public/modules-spec.md (add a "Travel categories" section).
Change:
- Data: ModuleCategory gains optional `taxKey` ('flights' | 'lodging' | 'rentals' | 'transport' | 'food' | 'host' | 'other') and `system: boolean`. Travel seed, all system: true, used: false, one per key: Flights / טיסות (flights), Lodging / לינה (lodging), Rentals / השכרות (rentals), Transport / תחבורה (transport), Food / אוכל (food), Host / אירוח (host), Other / אחר (other). Monthly and Petty Cash categories: system false, no taxKey (unchanged behaviour).
- Tax key labels (en / he): Flights / טיסות, Lodging / לינה, Rentals / השכרות, Transport / תחבורה, Food / אוכל, Host / אירוח, Other / אחר. Section label: "Tax key" / "סיווג מס".
- Travel rows: same single-line "HE / EN" name, plus a small outline Badge with the tax key label after the name. System rows also show a small Lock icon (aria-label/tooltip "System category - can only be deactivated" / "קטגוריית מערכת - ניתן רק להשבית").
- Actions on Travel rows:
  - System + active: NO Edit button; Delete button always shown -> confirm "Deactivate category?" / "להשבית את הקטגוריה?" body "System categories can't be deleted or renamed. It will be deactivated and can be reactivated later." / "לא ניתן למחוק או לשנות שם של קטגוריית מערכת. היא תושבת וניתן יהיה להפעיל אותה מחדש." confirm "Deactivate" / "השבתה".
  - System + inactive: Reactivate only.
  - Custom (system false): exactly like Monthly/Petty Cash (Edit + Delete, Delete deactivates when used).
  - Keep the action buttons column aligned: when Edit is hidden, keep an empty same-size placeholder.
- Add/edit dialog on Travel: an extra required Select "Tax key" (the seven labels), no default selected; Save disabled until a key is picked AND at least one name is filled. Editing a custom Travel category can change names and key. Duplicate-name check unchanged.
- Dev panel: "Mark all used/unused" and "Reset modules" also cover Travel.
Constraints: Hebrew RTL - Latin/numbers as LTR islands, logical CSS only; gender-neutral Hebrew, no addressing the reader; AA contrast; check both languages and 375px + desktop (badge + lock must not push the buttons to a new line - truncate the name first). No browser/Playwright runs or screenshots - a type check is enough.
Out of scope: Monthly / Petty Cash behaviour, any other screen. Do not refactor or rename.
Do not publish.
```
