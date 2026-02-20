# UX Upgrades - February 20, 2026

This document outlines all UX improvements needed to align the XpenseDesk Flutter app with the target design specification. Changes are organized into logical steps for incremental implementation.

---

## Overview

**Scope:** Global layout improvements + UI component standardization across all screens  
**Reference:** User Management Screen Design Alignment Guide  
**Approach:** Step-by-step implementation with verification after each step

**Important:** Most UI changes in this document are **global standards** that apply to ALL screens (Dashboard, Profile, Users Management, etc.), not just the Users screen. When implementing button styles, input fields, badges, or layout patterns, apply them consistently across the entire application.

---

## Global vs Screen-Specific Changes

### GLOBAL Standards (Apply Everywhere)
These changes affect the design system and must be applied consistently across ALL screens:

- **Phase 1:** Content width constraints (~720px centered layout)
- **Phase 2:** Theme colors and border radius standards
- **Phase 4, Step 4.2:** Primary and secondary button styling
- **Phase 5:** Input field borders and styling (all forms)
- **Phase 6, Steps 6.4-6.5:** Badge colors and styling (status, role, any badges)
- **Phase 8:** Content width application to all screens
- **Phase 9:** RTL support verification

**Screens Affected:** Users Management, Profile, Dashboard, and any future screens

### SCREEN-SPECIFIC Changes (Users Management Only)
These changes are specific to the Users Management screen:

- **Phase 3:** Replace AppBar with custom back button
- **Phase 4, Step 4.1:** Utilization counter styling
- **Phase 6, Steps 6.1-6.3, 6.6-6.7:** User list card structure, row layout, action menu behavior
- **Phase 7:** Invite Users dialog

---

## Phase 1: Global Layout Infrastructure

### Step 1.1: Add Content Width Constraint Component
**Goal:** Create a reusable container that constrains content to ~720px max width, centered

**What to build:**
- New widget: `lib/widgets/constrained_content.dart`
- Max width: 720px (equivalent to `max-w-3xl` in Tailwind)
- Centered horizontally with auto margins
- Mobile: 16-24px horizontal padding, natural width fill
- Should wrap content for all screens except login

**Why:** Currently content spans edge-to-edge (100% width). Target design uses centered, constrained content for better readability.

---

### Step 1.2: Verify Global Header Implementation
**Goal:** Ensure global header is consistently applied and matches target design

**What to verify:**
- `lib/widgets/header/app_header.dart` contains:
  - XpenseDesk logo/brand name on start side
  - Language switcher (flag icon + label) on end side
  - User avatar (initials circle) on end side
- Header is applied to ALL screens (not just some)
- Header works in both desktop and mobile layouts
- RTL support: elements flip correctly

**What might need changes:**
- If header is missing from any screen, add it
- Verify logo/brand name is visible (not just hamburger menu)
- Ensure language switcher and avatar are properly positioned

---

### Step 1.3: Verify Global Footer Implementation
**Goal:** Ensure global footer is consistently applied

**What to verify:**
- `lib/widgets/app_footer.dart` contains:
  - Privacy Policy link
  - Terms of Service link
  - Simple row layout, centered, muted text
- Footer is applied to ALL screens
- Works in both desktop and mobile layouts

**What might need changes:**
- If footer is missing from any screen, add it
- Verify styling matches muted/secondary color scheme

---

## Phase 2: Global Theme Refinements

### Step 2.1: Add Missing Color Tokens
**Goal:** Ensure all colors from design spec are available in theme for global use

**File:** `lib/theme/app_theme.dart`
**Impact:** All screens (Users, Profile, Dashboard, etc.)

**Add if missing:**
```dart
static const Color accent = Color(0xFF9B7FA9);      // hsl(280, 35%, 55%) - Pending badge
static const Color success = Color(0xFF16A34A);     // green-600 - Enable action
static const Color primaryTint = Color(0xFFEBE8F2); // primary/10% - Avatar backgrounds
```

**Verify existing:**
- Primary: `hsl(250, 45%, 30%)` = `#3D2E6B` ✓
- Background: `hsl(240, 20%, 98%)` = `#F7F7FC` ✓
- Border: `hsl(250, 20%, 90%)` = `#E5E3EE` ✓
- Muted text: `hsl(250, 10%, 45%)` = `#6B6580` ✓
- Destructive: `hsl(330, 81%, 60%)` = `#E63E7A` ✓

---

### Step 2.2: Update Border Radius Standard
**Goal:** Ensure consistent 12px (0.75rem) border radius globally

**File:** `lib/theme/app_theme.dart`
**Impact:** All screens - every button, input, card, dialog throughout the app

**Verify:**
- `borderRadius` constant = 12.0 ✓ (already correct)

**Apply to:**
- All card components (every screen)
- All button components (every screen)
- All input fields (Profile, Users, Login, etc.)
- All modal dialogs (Invite Users, confirmations, etc.)

---

## Phase 3: User Management Screen - Navigation

### Step 3.1: Replace AppBar with Custom Back Button
**Goal:** Remove the AppBar, add ghost-style back button with text label

**File:** `lib/screens/users_screen.dart`

**Changes:**
- Remove: `appBar: AppBar(...)` from Scaffold
- Add: Custom back button as first element in body column
- Button style:
  - Ghost/text button (no background)
  - Contains: Arrow icon + "Back to Dashboard" text
  - Icon: `Icons.arrow_back` (rotates 180° in RTL)
  - Position: Top-left of content area (below header)
  - Subtle hover effect
  - Bottom margin: 24px

**Create new widget:** `lib/widgets/users/back_button.dart` (optional, for reusability)

---

## Phase 4: Global Button and Typography Standards

### Step 4.1: Update Counter/Stats Typography (Users Screen)
**Goal:** Match target design typography and color for utilization counter

**File:** `lib/screens/users_screen.dart` (or extract to widget)

**Current:** Shows "Users: 15 of 14" (note: numbers seem wrong)

**Target styling:**
- Label "Users:" in muted/secondary text color (`mutedForeground`)
- Numbers in medium font weight
- Order: `{capacity} of {activeCount}` (e.g., "15 of 4")
- Fix the calculation to show correct numbers

**Note:** Verify the business logic - should be "X of 15" where X is current utilized, 15 is capacity.

---

### Step 4.2: Standardize Button Styling (Global)
**Goal:** Ensure all primary action buttons use consistent solid filled styling

**Files to verify/update:**
- `lib/theme/app_theme.dart` (FilledButton theme)
- `lib/screens/users_screen.dart` (Invite Users button)
- `lib/screens/profile_screen.dart` (Save/Update Profile button)
- `lib/screens/home_page.dart` (any action buttons)
- Any other screens with primary action buttons

**Standard for Primary Buttons:**
- Widget type: `FilledButton` or `FilledButton.icon`
- Background: primary color (`#3D2E6B`) from theme
- Text color: white (`primaryForeground`)
- Border radius: 12px (inherit from theme)
- Disabled state: reduced opacity (automatic with theme)

**Icon considerations:**
- Invite/Add User: `Icons.person_add_alt_1` (preferred) or `Icons.person_add`
- Save/Update: `Icons.check` or `Icons.save`
- Use icons that match the design system aesthetic

**Standard for Secondary Buttons:**
- Widget type: `OutlinedButton` or `TextButton`
- Border color: `border` gray from theme
- Text color: `foreground`
- Same border radius: 12px

**Apply globally:** Every screen should follow these button standards for visual consistency.

**Profile Screen Example:** The "Update Profile" button should use the same FilledButton style with primary background and 12px border radius. Any cancel/secondary buttons should use OutlinedButton or TextButton with the same border radius.

---

## Phase 5: Global Input Field Standards

### Step 5.1: Standardize Input Field Styling (Global)
**Goal:** Update all input fields to use consistent full rounded border style

**Files to update:**
- `lib/theme/app_theme.dart` (InputDecoration theme)
- `lib/screens/users_screen.dart` (search input)
- `lib/screens/profile_screen.dart` (name input, any other fields)
- `lib/screens/login_screen.dart` (if applicable)
- `lib/widgets/users/invite_users_dialog.dart` (email tag input)
- Any other forms/inputs throughout the app

**Standard for All Input Fields:**
- Border: Full rounded border all around (12px radius)
- Border color: light gray (`border` color from theme)
- Filled: true, white background
- Icons: Inside the input on start/end side as appropriate
- Placeholder: muted color
- Width: Full width within container

**Example InputDecoration pattern:**
```dart
decoration: InputDecoration(
  prefixIcon: const Icon(Icons.search),
  hintText: l10n.searchByNameOrEmail,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    borderSide: BorderSide(color: AppTheme.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    borderSide: BorderSide(color: AppTheme.border),
  ),
  // ... other states
),
```

**Apply globally:** Every input field across all screens should use this pattern (or define it in the theme's InputDecorationTheme).

**Profile Screen Example:** The "Full Name" input field should have the same full rounded border, 12px radius, and filled white background as the Users search field.

**Login Screen:** If applicable, ensure email/password fields also follow this pattern.

---

## Phase 6: Card and Badge Component Standards

### Step 6.1: Add Card Wrapper with Header (Users Screen)
**Goal:** Wrap user list in proper Card component with header

**File:** `lib/widgets/users/user_list_card.dart`
**Note:** This card styling pattern should be used for similar list/data displays in other screens

**Changes:**
- Card container:
  - Rounded corners: 12px
  - Border: 1px solid light gray (`border` color)
  - White background (`card` color)
  - Subtle shadow/elevation
- Card header section:
  - Contains: Users icon + "Users" title text
  - Padding: 16px
  - Border bottom: thin divider line
- List section:
  - Rows with internal dividers between them
  - No outer padding (dividers go edge-to-edge within card)

---

### Step 6.2: Update User Row Avatar Styling
**Goal:** Use primary color tint backgrounds instead of generic gray

**File:** `lib/widgets/users/user_row.dart` (or wherever row is defined)

**Changes:**
- Active users:
  - Background: `primaryTint` (primary color at 10% opacity)
  - Initials text color: primary color
- Disabled users:
  - Background: muted gray (`muted` color)
  - Initials text color: muted gray text
- Pending users:
  - Same as active (primary tint)

---

### Step 6.3: Update User Row Typography
**Goal:** Match target design font weights and sizes

**File:** `lib/widgets/users/user_row.dart`

**Changes:**
- Name:
  - Font weight: semibold/medium (FontWeight.w600)
  - Color: dark foreground
  - "(you)" marker: smaller muted text, inline after name
- Email:
  - Font size: small text (12-13px)
  - Color: muted color
  - Text overflow: ellipsis if too long
- Invited date (pending users only):
  - Extra small text (11px)
  - Icon: clock icon
  - Color: muted
  - Format: "Invited on MMM d, yyyy"

---

### Step 6.4: Standardize Badge Styling (Global)
**Goal:** Match target badge colors and styles across all screens

**Files to update:**
- `lib/widgets/users/status_badge.dart` (Users screen badges)
- `lib/widgets/users/role_badge.dart` (role badges - may appear elsewhere)
- Any other badge components used in Profile, Dashboard, or other screens

**Changes:**
- **Active badge:**
  - Background: primary tint (`primaryTint` or primary at 10% opacity)
  - Text color: primary color
  - NOT solid filled
- **Pending badge:**
  - Background: accent color background (`accent` with some opacity)
  - Text color: accent foreground (muted warm tone)
- **Disabled badge:**
  - Background: muted gray
  - Text color: muted gray text

**All badges (global standard):**
- Shape: rounded-full pill
- Padding: horizontal 10px (`px-2.5`), vertical 2px (`py-0.5`)
- Font size: 12px (`text-xs`)
- Font weight: medium (FontWeight.w500)

**Apply consistently:** These badge standards apply to any badge-like component across all screens (status indicators, role labels, tags, etc.)

---

### Step 6.5: Finalize Role Badge Colors (Global)
**Goal:** Ensure proper contrast and colors for role badges wherever they appear

**Files to update:**
- `lib/widgets/users/role_badge.dart`
- Any other locations where role information is displayed (Profile screen, Dashboard, etc.)

**Changes:**
- **Manager badge:**
  - Background: solid primary color (`primary`)
  - Text color: white (`primaryForeground`)
- **Employee badge:**
  - Background: light gray/secondary (`muted`)
  - Text color: dark text (`foreground`)

**Same styling as status badges:**
- Rounded-full pill shape
- Same padding and font size

**Global application:** Role badges may appear in user profile, dashboard user list, or anywhere user role is displayed. Apply consistently.

---

### Step 6.6: Hide Action Menu for Current User
**Goal:** Remove three-dot menu from the logged-in manager's own row

**File:** `lib/widgets/users/user_row.dart`

**Changes:**
- Check if user is the current logged-in user
- If yes: don't render the three-dot menu at all
- If no: render the menu as normal
- Use "(you)" marker as indicator - if name has "(you)", hide menu

**Logic:**
```dart
// Only show actions menu if not the current user
if (!isCurrentUser) {
  // ... render three-dot menu
}
```

---

### Step 6.7: Update Action Menu Dropdown Styling
**Goal:** Ensure menu items match design with proper icons and colors

**File:** `lib/widgets/users/user_actions_menu.dart` (or wherever dropdown is defined)

**Changes:**
- Three-dot icon: `Icons.more_vert` ✓ (keep vertical)
- Icon button: ghost style, 8x8 size
- Dropdown items:
  - **Promote to Manager / Demote to Employee:**
    - Icon: shield icon (`Icons.shield` or `Icons.admin_panel_settings`)
    - Text: neutral color
  - **Separator line** between role and status actions
  - **Enable:**
    - Icon: user check icon (`Icons.check_circle` or `Icons.person_outline`)
    - Text color: success/green
  - **Disable:**
    - Icon: user x icon (`Icons.cancel` or `Icons.person_off`)
    - Text color: destructive/red

---

## Phase 7: User Management Screen - Invite Dialog

### Step 7.1: Update Dialog Styling
**Goal:** Ensure modal matches design system

**File:** `lib/widgets/users/invite_users_dialog.dart`

**Verify/Update:**
- Dialog shape: 12px border radius
- Max width: appropriate for content (~500px)
- Padding: consistent with design system
- Background: white/card color
- Title typography: proper size and weight
- Subtitle (utilization counter): muted color

---

### Step 7.2: Verify Tag Input Component
**Goal:** Ensure email tag input works as specified

**File:** `lib/widgets/tag_input.dart`

**Features to verify:**
- Supports paste of comma/space-separated emails
- Validates email format
- De-duplicates against existing users
- Auto-trims to fit remaining slots
- Shows visual tags for each email
- Allows removal of individual tags

---

### Step 7.3: Update Role Selector Styling
**Goal:** Match dropdown design to search input style

**File:** `lib/widgets/users/invite_users_dialog.dart`

**Changes:**
- Use same border style as search input (full rounded border)
- Border radius: 12px
- Border color: light gray
- Filled background: white

---

### Step 7.4: Update Dialog Button Styling
**Goal:** Ensure footer buttons match design system

**File:** `lib/widgets/users/invite_users_dialog.dart`

**Changes:**
- **Cancel button:**
  - Style: outlined/border button
  - Border color: border gray
  - Text color: foreground
- **Invite button:**
  - Style: solid filled button
  - Background: primary color
  - Text color: white
  - Disabled state: reduced opacity when no emails entered

---

## Phase 8: Content Width Application (Global)

### Step 8.1: Apply Constrained Content to All Main Screens
**Goal:** Wrap all main screen content in the constrained width container

**Files to update (apply same pattern to all):**
- `lib/screens/users_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/home_page.dart` (dashboard)
- Any other main content screens (except login)

**Changes for each screen:**
- Wrap the main Column content with `ConstrainedContent` widget (from Step 1.1)
- Remove or adjust existing padding to work with the constraint
- Verify responsive behavior on mobile (should use padding, not max-width)
- Ensure global header and footer are outside the constraint (full width)

**Implementation approach:**
- Start with one screen (e.g., Users) to verify the pattern works
- Then apply the same approach to all other screens
- Test each screen after wrapping to ensure layout integrity

---

## Phase 9: RTL Support Verification

### Step 9.1: Verify RTL Layout Flipping
**Goal:** Ensure entire layout flips correctly for Hebrew/RTL

**Test scenarios:**
- Back arrow rotates 180 degrees in RTL ✓
- Search icon moves to end side
- Badges and action menu stay at end side
- Avatar and user info align correctly
- All spacing and padding flip correctly

**Files to check:**
- All user management widgets
- Global header and footer
- Search input
- Buttons and badges

---

### Step 9.2: Verify Logical Properties Usage
**Goal:** Ensure code uses start/end instead of left/right

**Search codebase for:**
- `Alignment.left` → should be `Alignment.start`
- `Alignment.right` → should be `Alignment.end`
- `EdgeInsets.only(left: ...)` → should be `EdgeInsets.only(start: ...)`
- Similar patterns in alignment, padding, margin

**Fix any hardcoded left/right references**

---

## Implementation Order Summary

**Recommended sequence:**

1. **Phase 1 (Steps 1.1-1.3):** Layout infrastructure - establishes foundation
2. **Phase 2 (Steps 2.1-2.2):** Global theme updates - ensures colors/constants available for all screens
3. **Phase 3 (Step 3.1):** Navigation changes - removes old AppBar (Users screen)
4. **Phase 4 (Steps 4.1-4.2):** Global button and typography standards - applies to ALL screens
5. **Phase 5 (Step 5.1):** Global input field standards - applies to ALL screens
6. **Phase 6 (Steps 6.1-6.7):** Card and badge standards - pattern for all screens, implemented on Users first
7. **Phase 7 (Steps 7.1-7.4):** Dialog standards - applies to all modal dialogs
8. **Phase 8 (Step 8.1):** Apply content width to all main screens - final layout polish
9. **Phase 9 (Steps 9.1-9.2):** RTL verification - final testing

**Total Steps:** 24 steps across 9 phases

**Key Point:** Most changes in Phases 2, 4, 5, and 6 are GLOBAL standards that must be applied consistently across Users Management, Profile, Dashboard, and all other screens.

---

## Testing Checklist

After implementation of each phase:

- [ ] Flutter build completes without errors
- [ ] Visual inspection in browser (desktop width)
- [ ] Visual inspection in browser (mobile width)
- [ ] Test RTL mode (Hebrew language)
- [ ] Verify responsive breakpoints (600px, 768px)
- [ ] Test all interactive elements (buttons, inputs, menus)
- [ ] Verify navigation flows
- [ ] Check console for warnings/errors

---

## Design Reference Summary

| Element | Current | Target | Scope |
|---------|---------|--------|-------|
| Content width | 100% edge-to-edge | ~720px centered | **GLOBAL** (all screens) |
| Primary buttons | FilledButton (\u2713) | Solid filled, 12px rounded | **GLOBAL** (Users, Profile, Dashboard) |
| Input borders | Default | Full rounded border (12px) | **GLOBAL** (all forms) |
| Status/role badges | Needs verification | Tinted/solid with proper colors | **GLOBAL** (anywhere badges appear) |
| Border radius | 12px \u2713 | 12px (already correct) | **GLOBAL** (all components) |
| Font | Assistant \u2713 | Assistant (already correct) | **GLOBAL** |
| Back button | Icon only | Icon + "Back to Dashboard" text | Users screen only |
| User list layout | Rows with dividers | Card wrapper with header | Users screen only |
| Avatar bg (active) | Generic | Primary tint (10% opacity) | Users screen (pattern reusable) |
| Three-dot menu | Shows for all | Hidden for current user | Users screen only |

---

## Notes

**Already Implemented Globally:** ✓
- **Assistant font** via Google Fonts (all screens)
- **Global header and footer** exist - need verification of usage
- **Most color tokens** in theme - need to add accent, success, primaryTint
- **Border radius standard** is already 12px ✓
- **FilledButton** is already being used ✓

**Key Focus Areas (Apply to ALL Screens):**
1. **Content width constraints** - biggest layout change, affects every screen
2. **Button styling** - primary/secondary standards apply everywhere (Users, Profile, Dashboard, etc.)
3. **Input field borders** - rounded border style applies to all forms (Profile name input, Users search, etc.)
4. **Badge colors** - role and status badges follow same rules wherever displayed
5. **Card patterns** - card wrapper and header pattern is reusable for all list/data displays

**Implementation Strategy:**
- Implement global standards in theme first (Phase 2)
- Apply to Users Management screen as reference implementation
- Systematically apply same patterns to Profile, Dashboard, and other screens
- Test each screen for consistency after applying global standards
