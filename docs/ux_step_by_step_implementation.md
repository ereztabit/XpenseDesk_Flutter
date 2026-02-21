# XpenseDesk UX Implementation Guide - Step by Step

**Last Updated:** February 20, 2026  
**Goal:** Complete UX transformation with visible progress after each step  
**Approach:** 19 incremental steps, each producing testable visual changes

---

## 🚀 CURRENT PROGRESS

**Completed Steps:**
- ✅ **Step 1:** Added theme colors (accent, success, primaryTint)
- ✅ **Step 2:** Users screen layout - removed AppBar, added centered 720px layout with header/footer, created LoginHeader widget separate from AppHeader, optimized provider watching to reduce flicker
- ✅ **Step 3:** Added custom back button ("← Back to Dashboard") to Users screen
- ✅ **Step 4:** Rounded border search input with white fill, 12px radius, purple focus border
- ✅ **Step 5:** Primary button styling - color #362B71, 50px minimumSize, shrinkWrap tap target
- ✅ **Step 6:** Counter typography with RichText - muted label, bold numbers
- ✅ **Step 7:** Card wrapper styling - border, flat elevation, localized header, theme colors
- ✅ **Step 8:** Avatar colors - primaryTint for active users, muted for disabled users (Updated: all users now use primaryTint for better visual presence)
- ✅ **Step 9:** Status badge colors - primaryTint/primary for active, accent for pending, muted for disabled, pill shape (Updated: disabled also uses primaryTint/primary for consistency)
- ✅ **Step 10:** Role badge colors - solid primary for Manager, muted for Employee, pill shape
- ✅ **Step 11:** User row typography - name 16px w600, "(you)" marker 14px muted, email 13px muted, invited date 11px with icon
- ✅ **Step 12:** Hide action menu for current user - already implemented with conditional rendering
- ✅ **Step 13:** Action menu styling - admin_panel_settings icon for role, color-coded enable (green) and disable (red/destructive)
- ✅ **Step 14:** Profile screen constrained layout - added AppHeader/Footer, wrapped content in ConstrainedContent, added back button
- ✅ **Step 15:** Profile screen form input styles - white fill, 12px radius, theme borders matching search input style

**Next Step:** 
- 🔜 **Step 16:** Continue remaining profile/dashboard improvements

**Notes from Implementation:**
- Created `lib/widgets/constrained_content.dart` - reusable 720px constraint wrapper
- Created `lib/widgets/header/login_header.dart` - dedicated header for login page
- Modified `lib/widgets/header/app_header.dart` - removed dual personality, only handles authenticated users
- Modified `lib/screens/users_screen.dart` - converted to StatefulWidget with session loading guard
- Small header flicker during navigation is acceptable (Flutter mounting behavior)
- Back button navigates to `/dashboard` route
- Primary color updated to #362B71 (affects all primary-colored elements)
- Button height: minimumSize 50px with shrinkWrap results in ~42px actual height

---

## How to Use This Guide

1. Implement one step at a time
2. Run `flutter build web` after each step
3. Take screenshot as specified
4. Verify all checkmarks pass
5. Get approval before moving to next step

**Screenshot naming:** `step-{number}-{description}.png`

---

## STEP 1: Add Theme Colors

**What we're doing:** Adding missing color tokens to the theme (accent, success, primaryTint)

**Files to modify:**
- `lib/theme/app_theme.dart`

**Changes:**
Add these constants after existing color definitions:
```dart
static const Color accent = Color(0xFF9B7FA9);      // hsl(280, 35%, 55%) - Pending badge
static const Color success = Color(0xFF16A34A);     // green-600 - Enable action
static const Color primaryTint = Color(0xFFEBE8F2); // primary/10% - Avatar backgrounds
```

**Build & Test:**
```bash
flutter build web
```

**What you'll see:**
- ✅ Build completes successfully
- ✅ No visual changes yet (colors added to theme but not used anywhere)

**Screenshot:** Not needed (no visual changes)

**Status:** Foundation step - enables all future color improvements

---

## STEP 2: Users Screen - Remove AppBar & Add Centered Layout

**What we're doing:** Removing the old AppBar and constraining content to ~720px centered width

**Files to modify:**
1. Create `lib/widgets/constrained_content.dart` (if not exists)
2. Modify `lib/screens/users_screen.dart`

**Changes to users_screen.dart:**
```dart
// Remove this from Scaffold:
appBar: AppBar(...),

// Wrap the body content in ConstrainedContent:
body: ConstrainedContent(
  child: Column(
    children: [
      // Move existing content here, but remove outer Padding
      // (ConstrainedContent handles padding)
      
      // Header bar with counter and invite button
      isNarrow ? Column(...) : Row(...),
      const SizedBox(height: 24),
      
      // Search bar
      TextField(...),
      const SizedBox(height: 24),
      
      // User list card
      const Expanded(child: UserListCard()),
    ],
  ),
),
```

**ConstrainedContent widget:**
```dart
// lib/widgets/constrained_content.dart
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 720.0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 24.0,
        ),
        child: child,
      ),
    );
  }
}
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ NO app bar at top (title bar is gone)
- ✅ Content is centered with white space on left/right (desktop)
- ✅ Content max width is ~720px
- ✅ Global header and footer still visible (full width)
- ✅ User list, search, buttons all constrained to center area

**Screenshot:** `step-2-users-centered-layout.png` (take at desktop width ~1200px)

**Why it matters:** This is the foundation layout pattern for all screens

---

## STEP 3: Users Screen - Add Custom Back Button

**What we're doing:** Adding a ghost-style back button with text

**Files to modify:**
- `lib/screens/users_screen.dart`
- `lib/l10n/app_en.arb` and `app_he.arb` (verify `backToDashboard` exists)

**Changes:**
Add as first child in the Column (inside ConstrainedContent):
```dart
Column(
  children: [
    // NEW: Back button
    Align(
      alignment: Alignment.centerStart,
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: Text(l10n.backToDashboard),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ),
    const SizedBox(height: 24),
    
    // Existing content continues...
    isNarrow ? Column(...) : Row(...),
  ],
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Back button with arrow icon + "Back to Dashboard" text at top-left
- ✅ No background on button (ghost/text style)
- ✅ 24px spacing below button
- ✅ Button hovers with subtle effect
- ✅ Clicking navigates back to dashboard

**Screenshot:** `step-3-back-button.png`

**Test in Hebrew:**
- Switch language to Hebrew
- ✅ Arrow should rotate 180° (pointing right)
- ✅ Text in Hebrew
- ✅ Button at top-right

**Why it matters:** Cleaner navigation than AppBar, matches design system

---

## STEP 4: Users Screen - Rounded Border Search Input

**What we're doing:** Updating search field to have full rounded border instead of underline

**Files to modify:**
- `lib/screens/users_screen.dart`

**Changes:**
Replace the TextField decoration:
```dart
TextField(
  decoration: InputDecoration(
    prefixIcon: const Icon(Icons.search),
    hintText: l10n.searchByNameOrEmail,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
    ),
  ),
  onChanged: (value) {
    ref.read(userSearchQueryProvider.notifier).setQuery(value);
  },
),
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Search input has rounded corners (12px radius)
- ✅ Full border all around (not just bottom)
- ✅ Light gray border color
- ✅ White background fill
- ✅ Search icon inside on left

**Test interaction:**
- Click into search field
- ✅ Border changes to purple (primary color) when focused
- ✅ Border is thicker (2px) when focused

**Screenshot:** `step-4-search-rounded.png` (take with field focused)

**Why it matters:** Modern input style, consistent with design system

---

## STEP 5: Users Screen - Update Invite Button

**What we're doing:** Verifying/updating primary button styling with rounded corners

**Files to modify:**
- `lib/theme/app_theme.dart` (add FilledButton theme if missing)
- `lib/screens/users_screen.dart` (update icon if needed)

**Changes to app_theme.dart:**
Add to lightTheme ThemeData:
```dart
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: primaryForeground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius), // 12px
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
),
```

**Changes to users_screen.dart (optional icon update):**
```dart
FilledButton.icon(
  icon: const Icon(Icons.person_add_alt_1), // Better icon than person_add
  label: Text(l10n.inviteUsers),
  onPressed: userStats.hasRemainingSlots
      ? () => _showInviteDialog(context, ref, userStats.remaining)
      : null,
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ "Invite Users" button has solid purple background (not outlined)
- ✅ White text
- ✅ Rounded corners (12px)
- ✅ Good padding (not cramped)
- ✅ Disabled state (gray/low opacity) when cap reached

**Screenshot:** `step-5-invite-button.png`

**Why it matters:** Primary button standard applies to ALL screens

---

## STEP 6: Users Screen - Update Counter Typography

**What we're doing:** Styling the utilization counter with proper colors and weights

**Files to modify:**
- `lib/screens/users_screen.dart`

**Changes:**
Replace the counter Text widget:
```dart
RichText(
  text: TextSpan(
    style: const TextStyle(
      fontSize: 16,
      color: AppTheme.foreground,
    ),
    children: [
      TextSpan(
        text: '${l10n.users}: ',
        style: const TextStyle(color: AppTheme.mutedForeground),
      ),
      TextSpan(
        text: '${userStats.utilized} ${l10n.of} ${userStats.capacity}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ],
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ "Users:" label in muted gray color
- ✅ Numbers (e.g., "4 of 15") in darker color
- ✅ Numbers are medium font weight (slightly bold)
- ✅ Clear visual hierarchy between label and numbers

**Screenshot:** `step-6-counter-typography.png`

**Why it matters:** Professional information hierarchy

---

## STEP 7: Users Screen - Add Card Wrapper to User List

**What we're doing:** Wrapping the user list in a Card with a header

**Files to modify:**
- `lib/widgets/users/user_list_card.dart`

**Changes:**
Restructure the widget:
```dart
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppTheme.border),
  ),
  elevation: 0,
  child: Column(
    children: [
      // NEW: Card Header
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.people, size: 20, color: AppTheme.foreground),
            const SizedBox(width: 8),
            Text(
              l10n.users,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: AppTheme.border),
      
      // Existing user list content
      Expanded(
        child: filteredUsers.when(
          data: (users) => ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: AppTheme.border,
            ),
            itemBuilder: (context, index) => UserRow(user: users[index]),
          ),
          // ... loading/error states
        ),
      ),
    ],
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ User list wrapped in white card with subtle border
- ✅ Card has rounded corners (12px)
- ✅ "Users" header at top with people icon
- ✅ Divider line below header
- ✅ User rows inside card with dividers between them
- ✅ Card looks professional and contained

**Screenshot:** `step-7-user-list-card.png`

**Why it matters:** Major visual upgrade, establishes card pattern for lists

---

## STEP 8: Users Screen - Update Avatar Colors

**What we're doing:** Using primary color tint for active users' avatars

**Files to modify:**
- Wherever CircleAvatar is rendered for users (likely in UserRow widget or user_list_card.dart)

**Changes:**
```dart
CircleAvatar(
  backgroundColor: user.isDisabled 
      ? AppTheme.muted 
      : AppTheme.primaryTint,
  child: Text(
    user.initials,
    style: TextStyle(
      color: user.isDisabled 
          ? AppTheme.mutedForeground 
          : AppTheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Active users: avatars have light purple/lavender background
- ✅ Active users: initials in dark purple
- ✅ Pending users: same as active (light purple background)
- ✅ Disabled users: gray background, gray text
- ✅ Brand colors instead of generic gray

**Screenshot:** `step-8-avatar-colors.png`

**Why it matters:** Brand consistency, visual distinction for user states

---

## STEP 9: Users Screen - Update Status Badge Colors

**What we're doing:** Using proper colors for Active (tint), Pending (accent), Disabled (gray)

**Files to modify:**
- Status badge rendering (likely in UserRow or separate badge widget)

**Changes:**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  decoration: BoxDecoration(
    color: status == 'active' 
        ? AppTheme.primaryTint 
        : status == 'pending'
            ? AppTheme.accent.withAlpha(26)  // ~10% opacity
            : AppTheme.muted,
    borderRadius: BorderRadius.circular(999), // pill shape
  ),
  child: Text(
    statusLabel,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: status == 'active'
          ? AppTheme.primary
          : status == 'pending'
              ? AppTheme.accent
              : AppTheme.mutedForeground,
    ),
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ "Active" badges: light purple background, dark purple text (NOT solid)
- ✅ "Pending" badges: light warm-tone background, accent text
- ✅ "Disabled" badges: gray background, gray text
- ✅ All badges are pill-shaped (fully rounded)
- ✅ Consistent sizing and padding

**Screenshot:** `step-9-status-badges.png`

**Why it matters:** Visual status hierarchy, matches design system

---

## STEP 10: Users Screen - Update Role Badge Colors

**What we're doing:** Manager solid primary, Employee muted gray

**Files to modify:**
- Role badge rendering

**Changes:**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  decoration: BoxDecoration(
    color: role == 'Manager' ? AppTheme.primary : AppTheme.muted,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(
    roleLabel,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: role == 'Manager' 
          ? AppTheme.primaryForeground 
          : AppTheme.foreground,
    ),
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ "Manager" badges: solid dark purple, white text, high contrast
- ✅ "Employee" badges: light gray background, dark text
- ✅ Clear visual distinction between roles
- ✅ Manager badge stands out more (higher authority)

**Screenshot:** `step-10-role-badges.png`

**Why it matters:** Clear role identification at a glance

---

## STEP 11: Users Screen - Update User Row Typography

**What we're doing:** Proper font weights, sizes, and "(you)" marker

**Files to modify:**
- UserRow widget or wherever user name/email is displayed

**Changes:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Name with "(you)" marker
    Row(
      children: [
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        if (user.isCurrentUser) ...[
          const SizedBox(width: 6),
          Text(
            '(${l10n.you})',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: 4),
    
    // Email
    Text(
      user.email,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.mutedForeground,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    
    // Invited date (pending users only)
    if (user.status == 'pending' && user.invitedDate != null) ...[
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(Icons.schedule, size: 12, color: AppTheme.mutedForeground),
          const SizedBox(width: 4),
          Text(
            'Invited on ${formatDate(user.invitedDate!)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    ],
  ],
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Names are bold/semibold (w600)
- ✅ Current user has "(you)" marker in smaller, muted text
- ✅ Emails in smaller font (13px), muted color
- ✅ Pending users show clock icon + "Invited on [date]" in tiny text
- ✅ Clear information hierarchy

**Screenshot:** `step-11-user-row-typography.png`

**Why it matters:** Professional typography hierarchy, clear status indicators

---

## STEP 12: Users Screen - Hide Action Menu for Current User

**What we're doing:** Don't show three-dot menu on your own row

**Files to modify:**
- UserRow widget

**Changes:**
```dart
// In the row layout, conditionally render menu:
Row(
  children: [
    // Avatar, name/email, badges...
    
    const Spacer(),
    
    // Badges
    StatusBadge(status: user.status),
    const SizedBox(width: 8),
    RoleBadge(role: user.role),
    
    // Action menu - ONLY if not current user
    if (!user.isCurrentUser) ...[
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.more_vert),
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        onPressed: () => _showActionsMenu(context, user),
      ),
    ],
  ],
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Your own row (with "(you)" marker) has NO three-dot menu
- ✅ All other user rows have the three-dot menu
- ✅ Your row looks clean and symmetrical
- ✅ Clear visual indicator you can't modify yourself

**Screenshot:** `step-12-no-self-menu.png`

**Why it matters:** Prevents accidental self-modification, UX safety

---

## STEP 13: Users Screen - Update Action Menu Styling

**What we're doing:** Proper icons and color-coded actions (green Enable, red Disable)

**Files to modify:**
- Action menu dropdown component

**Changes:**
```dart
PopupMenuButton(
  icon: const Icon(Icons.more_vert),
  itemBuilder: (context) => [
    // Role toggle
    PopupMenuItem(
      onTap: () => _toggleRole(user),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, size: 18),
          const SizedBox(width: 12),
          Text(user.role == 'Manager' 
              ? l10n.demoteToEmployee 
              : l10n.promoteToManager),
        ],
      ),
    ),
    const PopupMenuDivider(),
    
    // Status toggle
    PopupMenuItem(
      onTap: () => _toggleStatus(user),
      child: Row(
        children: [
          Icon(
            user.isDisabled ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: user.isDisabled ? AppTheme.success : AppTheme.destructive,
          ),
          const SizedBox(width: 12),
          Text(
            user.isDisabled ? l10n.enable : l10n.disable,
            style: TextStyle(
              color: user.isDisabled ? AppTheme.success : AppTheme.destructive,
            ),
          ),
        ],
      ),
    ),
  ],
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Click three-dot menu on any user (not yours)
- ✅ Promote/Demote option with shield icon
- ✅ Divider line between role and status actions
- ✅ Enable action in GREEN (success color) for disabled users
- ✅ Disable action in RED (destructive color) for active users
- ✅ Icons match action types

**Screenshot:** `step-13-action-menu.png` (take with menu open)

**Why it matters:** Color-coded severity, clear visual feedback

---

## STEP 14: Profile Screen - Apply Constrained Layout

**What we're doing:** Same centered ~720px layout on Profile screen

**Files to modify:**
- `lib/screens/profile_screen.dart`

**Changes:**
Wrap main content in ConstrainedContent:
```dart
Scaffold(
  body: Column(
    children: [
      // Global header stays outside
      AppHeader(),
      
      // Content constrained
      Expanded(
        child: ConstrainedContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile form content
              ],
            ),
          ),
        ),
      ),
      
      // Global footer stays outside
      AppFooter(),
    ],
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/profile` or `/employee/profile`

**What you'll see:**
- ✅ Profile content centered with ~720px max width
- ✅ White space margins on sides (desktop)
- ✅ Form fields contained in center area
- ✅ Global header/footer full width (outside constraint)
- ✅ Matches Users screen layout pattern

**Screenshot:** `step-14-profile-layout.png`

**Why it matters:** Consistent layout across all screens

---

## STEP 15: Profile Screen - Update Form Input Styles

**What we're doing:** Apply rounded borders to profile inputs

**Files to modify:**
- `lib/screens/profile_screen.dart`

**Changes:**
Apply to Full Name input:
```dart
TextFormField(
  controller: _fullNameController,
  decoration: InputDecoration(
    labelText: l10n.fullName,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.destructive),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.destructive, width: 2),
    ),
  ),
  validator: _validateFullName,
)
```

Apply same pattern to Language dropdown if using DropdownMenu:
```dart
DropdownMenu<int>(
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
  ),
  // ... rest of dropdown config
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** Profile screen

**What you'll see:**
- ✅ Full Name input has rounded border (12px)
- ✅ Light gray border, white fill
- ✅ Language dropdown has same rounded border
- ✅ Inputs match Users screen search field style
- ✅ Focus state: purple border (2px)
- ✅ Error state: red border

**Screenshot:** `step-15-profile-inputs.png`

**Why it matters:** Consistent input styling across all forms

---

## STEP 16: Profile Screen - Verify Save Button Style

**What we're doing:** Ensure save button has primary styling

**Files to modify:**
- `lib/screens/profile_screen.dart`

**Changes:**
Ensure button uses FilledButton:
```dart
FilledButton.icon(
  onPressed: _isLoading ? null : _handleSave,
  icon: const Icon(Icons.check),
  label: Text(l10n.updateProfile),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** Profile screen

**What you'll see:**
- ✅ Save/Update button has solid purple background
- ✅ White text, check icon
- ✅ Rounded corners (12px)
- ✅ Matches Invite Users button style from Users screen
- ✅ Disabled state (gray) while loading

**Screenshot:** `step-16-profile-button.png`

**Why it matters:** Button consistency across all screens

---

## STEP 17: Dashboard - Apply Constrained Layout

**What we're doing:** Same centered ~720px layout on Dashboard

**Files to modify:**
- `lib/screens/home_page.dart`

**Changes:**
Wrap main content in ConstrainedContent:
```dart
Scaffold(
  body: Column(
    children: [
      AppHeader(),
      
      Expanded(
        child: ConstrainedContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                // Dashboard content
              ],
            ),
          ),
        ),
      ),
      
      AppFooter(),
    ],
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** `/manager/dashboard` or `/employee/dashboard`

**What you'll see:**
- ✅ Dashboard content centered with ~720px max width
- ✅ White space margins on sides (desktop)
- ✅ Consistent with Users and Profile screens
- ✅ All main screens now have unified layout

**Screenshot:** `step-17-dashboard-layout.png`

**Why it matters:** Complete layout consistency across entire app

---

## STEP 18: Invite Dialog - Polish Styling

**What we're doing:** Ensure dialog matches design system

**Files to modify:**
- `lib/widgets/users/invite_users_dialog.dart`

**Changes:**
Update dialog styling:
```dart
Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Container(
    constraints: const BoxConstraints(maxWidth: 500),
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          l10n.inviteNewUser,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          l10n.usersCount(utilization, capacity),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 24),
        
        // Email tag input
        TagInput(...),
        const SizedBox(height: 16),
        
        // Role dropdown with rounded border
        DropdownMenu<int>(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
          // ...
        ),
        const SizedBox(height: 24),
        
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: emails.isEmpty ? null : _handleInvite,
              child: Text(l10n.inviteUsers),
            ),
          ],
        ),
      ],
    ),
  ),
)
```

**Build & Test:**
```bash
flutter build web
```

**Navigate to:** Users screen, click "Invite Users"

**What you'll see:**
- ✅ Dialog has rounded corners (12px)
- ✅ Max width constraint (~500px)
- ✅ Role dropdown has rounded border matching inputs
- ✅ Cancel button is outlined (not filled)
- ✅ Invite button is solid purple (FilledButton)
- ✅ Invite button disabled when no emails entered

**Screenshot:** `step-18-invite-dialog.png`

**Why it matters:** Dialog consistency with design system

---

## STEP 19: RTL Verification

**What we're doing:** Testing all screens in Hebrew (RTL mode)

**No code changes** - this is a verification step

**Test Sequence:**

### 19a. Switch to Hebrew
1. Click language switcher in global header
2. Select Hebrew

### 19b. Test Users Screen
**Navigate to:** `/manager/users`

**What you'll see:**
- ✅ Back button at top-right (arrow points right)
- ✅ Content still centered
- ✅ Search icon on right side of input
- ✅ Invite button on left side
- ✅ User avatars on right
- ✅ Badges and three-dot menu on left side
- ✅ All text in Hebrew

**Screenshot:** `step-19a-users-rtl.png`

### 19c. Test Profile Screen
**Navigate to:** Profile screen

**What you'll see:**
- ✅ Content centered (RTL aware)
- ✅ Form fields align correctly
- ✅ Labels on right side
- ✅ Save button in correct position
- ✅ All text in Hebrew

**Screenshot:** `step-19b-profile-rtl.png`

### 19d. Test Dashboard
**Navigate to:** Dashboard

**What you'll see:**
- ✅ Content centered and flipped
- ✅ Layout adapts to RTL
- ✅ All text in Hebrew

**Screenshot:** `step-19c-dashboard-rtl.png`

### 19e. Test Invite Dialog
**Navigate to:** Users screen, click "Invite Users"

**What you'll see:**
- ✅ Dialog content flips to RTL
- ✅ Buttons in correct RTL positions
- ✅ All text in Hebrew

**Screenshot:** `step-19d-dialog-rtl.png`

**Why it matters:** Full RTL support for Hebrew users

---

## Completion Checklist

After all 19 steps:

- [ ] **Step 1:** Theme colors added ✓
- [ ] **Step 2:** Users screen centered layout ✓
- [ ] **Step 3:** Custom back button ✓
- [ ] **Step 4:** Search input rounded border ✓
- [ ] **Step 5:** Invite button styling ✓
- [ ] **Step 6:** Counter typography ✓
- [ ] **Step 7:** User list card wrapper ✓
- [ ] **Step 8:** Avatar colors (primary tint) ✓
- [ ] **Step 9:** Status badge colors ✓
- [ ] **Step 10:** Role badge colors ✓
- [ ] **Step 11:** User row typography ✓
- [ ] **Step 12:** Hide self action menu ✓
- [ ] **Step 13:** Action menu styling ✓
- [ ] **Step 14:** Profile centered layout ✓
- [ ] **Step 15:** Profile input styles ✓
- [ ] **Step 16:** Profile button style ✓
- [ ] **Step 17:** Dashboard centered layout ✓
- [ ] **Step 18:** Invite dialog polish ✓
- [ ] **Step 19:** RTL verification ✓

---

## Summary

**Total Steps:** 19  
**Screens Updated:** Users Management, Profile, Dashboard  
**Global Standards Applied:**
- Constrained ~720px centered layout
- Rounded border inputs (12px)
- Primary button styling
- Badge color system
- Typography hierarchy
- RTL support

**Result:** Cohesive, professional design system applied across the entire app
