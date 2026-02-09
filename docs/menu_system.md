# Menu System Guide

## Overview

The application uses a responsive menu system that adapts to screen size:
- **Desktop (768px+)**: Avatar popover menu (Jira-style)
- **Mobile (<768px)**: Side sheet menu sliding from right

## Architecture

### File Structure

```
lib/
├── models/
│   └── menu_items.dart          # Single source of truth for menu data
└── widgets/
    └── header/
        ├── app_header.dart      # Responsive coordinator
        ├── desktop_menu.dart    # Desktop popover implementation
        └── mobile_menu_sheet.dart # Mobile side sheet implementation
```

### Components

1. **MenuItems** (lib/models/menu_items.dart)
   - Data model and utilities
   - Defines all menu items with metadata
   - Provides filtering logic and helper methods

2. **AppHeader** (lib/widgets/header/app_header.dart)
   - Main header bar component
   - Handles responsive breakpoint logic
   - Coordinates between desktop and mobile menus

3. **DesktopMenu** (lib/widgets/header/desktop_menu.dart)
   - Popover menu for desktop viewports
   - Fade animation (150ms)
   - Positioned below avatar, right-aligned

4. **MobileMenuSheet** (lib/widgets/header/mobile_menu_sheet.dart)
   - Side sheet for mobile viewports
   - Slide-in from right (500ms), slide-out (300ms)
   - Black backdrop with 80% opacity

## Menu Item Structure

Each menu item has the following properties:

```dart
MenuItem(
  id: 'unique-identifier',           // Used for routing/actions
  icon: Icons.icon_name,              // Material Design icon
  label: t.localizedString,           // Localized display text
  requiresManagerRole: false,         // true = manager only
  isDestructive: false,               // true = destructive action (logout)
)
```

## How It Works

### Responsive Behavior

AppHeader checks viewport width and displays appropriate trigger:

```dart
final isMobile = MediaQuery.of(context).size.width < 768;

if (isMobile) {
  // Show hamburger icon
  // Opens MobileMenuSheet on tap
} else {
  // Show avatar circle
  // Opens DesktopMenu on tap
}
```

### Menu Item Filtering

Menu items are automatically filtered based on user role:

```dart
MenuItems.getItems(t, isManager)
// Returns all items if isManager = true
// Filters out requiresManagerRole items if isManager = false
```

### Current Menu Items

1. **My Profile** - Available to all users
2. **Spend History** - Manager only
3. **Company Configuration** - Manager only
4. **User Management** - Manager only
5. **Logout** - Available to all users (destructive action)

## Adding New Menu Items

Follow these steps to add a new menu item:

### Step 1: Add Localization Strings

Edit localization files with the new menu item label:

**lib/l10n/app_en.arb:**
```json
{
  "myNewFeature": "My New Feature",
  "@myNewFeature": {
    "description": "Menu item for new feature"
  }
}
```

**lib/l10n/app_he.arb:**
```json
{
  "myNewFeature": "התכונה החדשה שלי"
}
```

### Step 2: Add Menu Item to MenuItems Class

Edit **lib/models/menu_items.dart** and add your item to the allItems list:

```dart
static List<MenuItem> getItems(AppLocalizations t, bool isManager) {
  final allItems = [
    MenuItem(
      id: 'profile',
      icon: Icons.person_outline,
      label: t.myProfile,
    ),
    // ... existing items ...
    
    // Add your new item here
    MenuItem(
      id: 'my-new-feature',              // Unique ID
      icon: Icons.star_outline,           // Choose appropriate icon
      label: t.myNewFeature,              // Use localized string
      requiresManagerRole: false,         // Set to true for manager-only
      isDestructive: false,               // Set to true for destructive actions
    ),
    
    MenuItem(
      id: 'logout',
      icon: Icons.logout,
      label: t.logout,
      isDestructive: true,
    ),
  ];
  
  return allItems
      .where((item) => !item.requiresManagerRole || isManager)
      .toList();
}
```

**Important:** Keep destructive items (like logout) at the end of the list. They will be separated with a divider automatically.

### Step 3: Add Route Handling

Edit **lib/widgets/header/app_header.dart** to handle navigation for the new item:

```dart
void _handleMenuItemSelected(String value) async {
  final tokenInfo = ref.read(tokenInfoProvider);
  if (tokenInfo == null) return;

  _closeMenu();

  switch (value) {
    case 'profile':
      final role = _isManager(tokenInfo.roleId) ? 'manager' : 'employee';
      if (mounted) Navigator.pushNamed(context, '/$role/profile');
      break;
    
    // Add your new route here
    case 'my-new-feature':
      if (mounted) Navigator.pushNamed(context, '/my-new-feature');
      break;
    
    case 'spend-history':
      if (mounted) Navigator.pushNamed(context, '/manager/history');
      break;
    // ... other cases ...
  }
}
```

If your item is available in the mobile menu sheet, also update **lib/widgets/header/mobile_menu_sheet.dart**:

```dart
void _handleMenuItemSelected(String value) async {
  await _close();

  if (value == 'logout') {
    // Logout logic
  } else if (value == 'my-new-feature') {
    if (mounted) {
      Navigator.of(context).pushNamed('/my-new-feature');
    }
  }
  // Add navigation for other items as needed
}
```

### Step 4: Test Both Platforms

1. **Desktop Test** (viewport >= 768px):
   - Click avatar
   - Verify new item appears in correct position
   - Verify click navigates correctly

2. **Mobile Test** (viewport < 768px):
   - Click hamburger menu
   - Verify new item appears in side sheet
   - Verify click navigates correctly

3. **Role-Based Test** (if requiresManagerRole = true):
   - Login as employee - item should NOT appear
   - Login as manager - item SHOULD appear

## Styling Customization

### Colors

Menu colors are defined using AppTheme constants:

- **Avatar background**: AppTheme.primary with 10% opacity (withAlpha(25))
- **Avatar text**: AppTheme.primary
- **Menu item icons**: AppTheme.mutedForeground
- **Menu item text**: AppTheme.foreground (or AppTheme.mutedForeground for destructive)
- **Menu background**: AppTheme.card
- **Borders**: AppTheme.border

### Icons

Use Material Design icons from the Icons class:
- Icons.person_outline
- Icons.history
- Icons.settings_outlined
- Icons.people_outline
- Icons.logout

Browse full icon set: https://api.flutter.dev/flutter/material/Icons-class.html

### Positioning

Desktop menu positioning (lib/widgets/header/desktop_menu.dart):
```dart
final menuWidth = 288.0;  // Fixed width
final menuLeft = widget.offset.dx + widget.avatarSize.width - menuWidth;  // Right-aligned
final menuTop = widget.offset.dy + widget.avatarSize.height + 8;  // 8px below avatar
```

Mobile menu width (lib/widgets/header/mobile_menu_sheet.dart):
```dart
final sheetWidth = (screenWidth * 0.75).clamp(0.0, 384.0);  // 75% of screen, max 384px
```

## Animations

### Desktop Menu
- **Duration**: 150ms
- **Type**: Fade only
- **Curve**: easeOut

### Mobile Menu
- **Slide-in**: 500ms, easeOut
- **Slide-out**: 300ms, easeIn
- **Backdrop fade**: Matches slide animation

## Accessibility

### Keyboard Support
- **ESC key**: Closes desktop menu (KeyboardListener)
- **Tab navigation**: Handled by InkWell focus

### Click-Outside-to-Close
- Desktop: GestureDetector wraps entire overlay
- Mobile: Backdrop tap closes menu

## Common Issues

### Menu Item Not Appearing
1. Check localization strings are added to both app_en.arb and app_he.arb
2. Verify item is added to allItems list in MenuItems.getItems()
3. If manager-only: Check requiresManagerRole flag and user roleId

### Navigation Not Working
1. Verify route handler is added to _handleMenuItemSelected in app_header.dart
2. Check route is defined in main.dart route configuration
3. Ensure Navigator.pushNamed uses correct route path

### Icon Not Displaying
1. Verify icon name exists in Material Icons
2. Check import statement includes 'package:flutter/material.dart'
3. Ensure icon property uses Icons.icon_name format

### Wrong Colors
1. Check you're using AppTheme constants, not hardcoded colors
2. Verify you're using withAlpha() not deprecated withOpacity()
3. Use theme inspection tools to verify theme values

## Future Enhancements

Potential improvements to the menu system:

1. **Sub-menus**: Add nested menu support for grouped items
2. **Badges**: Add notification badges to menu items
3. **Search**: Add search functionality for large menus
4. **Customization**: Allow users to reorder menu items
5. **Keyboard shortcuts**: Display shortcuts next to menu items
6. **Analytics**: Track menu item usage
