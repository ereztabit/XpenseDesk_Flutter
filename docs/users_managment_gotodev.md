# User Management Module - Implementation Plan

## Overview
This document outlines the step-by-step implementation plan for the User Management Console (`/manager/users`), combining UX requirements with API integration.

**Target Route**: `/manager/users`  
**User Role**: Administrator only (RoleId: 1)  
**Primary APIs**: `/api/users/*` endpoints

---

## Architecture Overview

```
lib/
├── models/
│   └── user_list_item.dart          # User model for list display
├── services/
│   └── users_service.dart           # API client for user management
├── providers/
│   └── users_provider.dart          # State management for user list
├── widgets/
│   └── users/
│       ├── user_list_card.dart      # Main user list component
│       ├── user_list_item.dart      # Individual user row
│       ├── invite_users_dialog.dart # Modal for inviting users
│       └── user_actions_menu.dart   # Dropdown actions menu
└── screens/
    └── users_screen.dart            # Main screen container
```

---

## Implementation Steps

### Step 1: Create User Models
**Goal**: Define data structures for user management

**Files to Create**:
- `lib/models/user_list_item.dart`

**Model Structure**:
```dart
class UserListItem {
  final String userId;
  final String email;
  final String fullName;
  final int roleId;
  final String status;  // 'Active', 'Pending', 'Disabled'
  final DateTime? invitedDate;  // Only for pending users
  
  // Computed properties
  String get roleName => roleId == 1 ? 'Manager' : 'Employee';
  bool get isActive => status == 'Active';
  bool get isPending => status == 'Pending';
  bool get isDisabled => status == 'Disabled';
  String get initials;  // Extract from fullName
}
```

**Expected API Response** (from `/api/users/all`):
```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": [
    {
      "userId": "guid",
      "email": "user@company.com",
      "fullName": "User Name",
      "roleId": 2,
      "status": "Active"
    }
  ]
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Model has fromJson/toJson methods

---

### Step 2: Create Users Service
**Goal**: Implement API client for user management operations

**Files to Create**:
- `lib/services/users_service.dart`

**Service Methods**:
```dart
class UsersService {
  // GET /api/users/all
  Future<List<UserListItem>> getAllUsers();
  
  // POST /api/users/invite
  Future<void> inviteUsers(List<String> emails, int roleId);
  
  // POST /api/users/promote-to-admin
  Future<void> promoteToAdmin(String targetUserId);
  
  // POST /api/users/downgrade-to-user
  Future<void> downgradeToEmployee(String targetUserId);
  
  // POST /api/users/disable
  Future<void> disableUser(String targetUserId);
  
  // POST /api/users/enable
  Future<void> enableUser(String targetUserId);
}
```

**API Request Examples**:

**Get All Users**:
```http
GET /api/users/all
Authorization: Bearer {token}
```

**Invite Users**:
```http
POST /api/users/invite
Authorization: Bearer {token}
Content-Type: application/json

{
  "emails": ["user1@company.com", "user2@company.com"]
}
```

**Promote to Admin**:
```http
POST /api/users/promote-to-admin
Authorization: Bearer {token}
Content-Type: application/json

{
  "targetUserId": "guid"
}
```

**Downgrade to Employee**:
```http
POST /api/users/downgrade-to-user
Authorization: Bearer {token}
Content-Type: application/json

{
  "targetUserId": "guid"
}
```

**Disable User**:
```http
POST /api/users/disable
Authorization: Bearer {token}
Content-Type: application/json

{
  "targetUserId": "guid"
}
```

**Enable User**:
```http
POST /api/users/enable
Authorization: Bearer {token}
Content-Type: application/json

{
  "targetUserId": "guid"
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Service uses `ApiService` pattern
- [ ] All methods have proper error handling

---

### Step 3: Create Users Provider
**Goal**: Implement state management for user list and operations

**Files to Create**:
- `lib/providers/users_provider.dart`

**Provider Structure**:
```dart
// Service provider
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

// Users list provider (async)
final usersListProvider = FutureProvider<List<UserListItem>>((ref) async {
  final service = ref.watch(usersServiceProvider);
  return service.getAllUsers();
});

// Filtered users provider (for search)
final filteredUsersProvider = Provider<List<UserListItem>>((ref) {
  final usersAsync = ref.watch(usersListProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);
  
  return usersAsync.when(
    data: (users) {
      if (searchQuery.isEmpty) return users;
      return users.where((user) {
        return user.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
               user.email.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Search query provider
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// User count statistics provider
final userStatsProvider = Provider<UserStats>((ref) {
  final usersAsync = ref.watch(usersListProvider);
  return usersAsync.when(
    data: (users) {
      final activeCount = users.where((u) => u.isActive).length;
      final pendingCount = users.where((u) => u.isPending).length;
      final utilized = activeCount + pendingCount;
      return UserStats(
        utilized: utilized,
        capacity: 15,
        remaining: 15 - utilized,
      );
    },
    loading: () => UserStats(utilized: 0, capacity: 15, remaining: 15),
    error: (_, __) => UserStats(utilized: 0, capacity: 15, remaining: 15),
  );
});
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Providers follow Riverpod patterns

---

### Step 4: Create User List Item Widget
**Goal**: Build individual user row component

**Files to Create**:
- `lib/widgets/users/user_list_item.dart`

**Widget Structure**:
```dart
class UserListItem extends StatelessWidget {
  final UserListItem user;
  final bool isCurrentUser;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Avatar with initials
      leading: CircleAvatar(...),
      
      // Name and email
      title: Row(
        children: [
          Text(user.fullName),
          if (isCurrentUser) Text(' (you)'),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (user.isPending) _buildInvitedDate(),
        ],
      ),
      
      // Status and role badges
      trailing: Row(
        children: [
          _buildStatusBadge(),
          _buildRoleBadge(),
          if (!isCurrentUser) UserActionsMenu(...),
        ],
      ),
    );
  }
}
```

**UI Elements**:
- Avatar: Circle with initials, dimmed if disabled
- Name: Bold, with "(you)" suffix for current user
- Email: Muted text, truncated if long
- Invited Date: Clock icon + "Invited on Jan 28, 2025" (pending only)
- Status Badge: `Active` (primary), `Pending` (accent), `Disabled` (muted)
- Role Badge: `Manager` (primary/solid), `Employee` (secondary)
- Actions Menu: Three dots (hidden for current user)

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Widget renders correctly in isolation

---

### Step 5: Create User Actions Menu Widget
**Goal**: Build dropdown menu for user actions

**Files to Create**:
- `lib/widgets/users/user_actions_menu.dart`

**Widget Structure**:
```dart
class UserActionsMenu extends StatelessWidget {
  final UserListItem user;
  final VoidCallback onPromote;
  final VoidCallback onDemote;
  final VoidCallback onDisable;
  final VoidCallback onEnable;
  
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) => [
        // Promote/Demote option
        PopupMenuItem(
          value: user.roleId == 1 ? 'demote' : 'promote',
          child: Row(
            children: [
              Icon(Icons.shield),
              Text(user.roleId == 1 ? 'Demote to Employee' : 'Promote to Manager'),
            ],
          ),
        ),
        PopupMenuDivider(),
        // Disable/Enable option
        PopupMenuItem(
          value: user.isDisabled ? 'enable' : 'disable',
          child: Row(
            children: [
              Icon(user.isDisabled ? Icons.check : Icons.block),
              Text(user.isDisabled ? 'Enable' : 'Disable'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'promote': onPromote();
          case 'demote': onDemote();
          case 'disable': onDisable();
          case 'enable': onEnable();
        }
      },
    );
  }
}
```

**Menu Items**:
- **Promote to Manager** / **Demote to Employee** (shield icon)
- Separator line
- **Disable** (red/destructive) / **Enable** (green)

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Menu styling matches design

---

### Step 6: Create Invite Users Dialog
**Goal**: Build modal for inviting new users

**Files to Create**:
- `lib/widgets/users/invite_users_dialog.dart`

**Widget Structure**:
```dart
class InviteUsersDialog extends StatefulWidget {
  final int remainingSlots;
  
  @override
  _InviteUsersDialogState createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog> {
  final _emailController = TextEditingController();
  int _selectedRoleId = 2; // Default to Employee
  List<String> _emailList = [];
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Text('Invite New Users'),
          Text('Users: X out of 15', style: caption),
        ],
      ),
      content: Column(
        children: [
          // Email input field with multi-email support
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Addresses',
              hintText: 'Paste or type emails...',
              helperText: 'Separate with spaces or commas (11 slots remaining)',
            ),
          ),
          
          // Role selector dropdown
          DropdownMenu<int>(
            label: Text('Role'),
            initialSelection: 2,
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 2, label: 'Employee'),
              DropdownMenuEntry(value: 1, label: 'Manager'),
            ],
            onSelected: (value) {
              setState(() => _selectedRoleId = value ?? 2);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: _emailList.isEmpty ? null : _handleInvite,
          child: Text('Invite Users'),
        ),
      ],
    );
  }
  
  void _handleInvite() async {
    // Parse emails, validate, deduplicate, trim to remaining slots
    // Call API via provider
    // Close dialog on success
  }
}
```

**Dialog Elements**:
- Title: "Invite New Users"
- Subtitle: User utilization counter
- Email field: Multi-email text input with validation
- Slots indicator: "X slots remaining" or warning if full
- Role selector: Employee or Manager dropdown
- Actions: Cancel (outline) and Invite Users (primary, disabled if empty)

**Business Logic**:
- Parse comma/space-separated emails
- Validate email format
- Deduplicate entries
- Auto-trim to remaining slots (max 20 per batch, but also respect plan cap)
- Show error toast if no valid emails

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Dialog opens and closes correctly
- [ ] Email validation works

---

### Step 7: Create User List Card Widget
**Goal**: Build main user list container

**Files to Create**:
- `lib/widgets/users/user_list_card.dart`

**Widget Structure**:
```dart
class UserListCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
    final currentUser = ref.watch(userInfoProvider);
    
    return Card(
      child: Column(
        children: [
          // Card header with icon and title
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
          ),
          Divider(),
          
          // User list
          usersAsync.when(
            data: (users) {
              if (filteredUsers.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isCurrentUser = user.email == currentUser?.email;
                  
                  return UserListItem(
                    user: user,
                    isCurrentUser: isCurrentUser,
                    onPromote: () => _handlePromote(ref, user),
                    onDemote: () => _handleDemote(ref, user),
                    onDisable: () => _handleDisable(ref, user),
                    onEnable: () => _handleEnable(ref, user),
                  );
                },
              );
            },
            loading: () => CircularProgressIndicator(),
            error: (err, stack) => ErrorWidget(err),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handlePromote(WidgetRef ref, UserListItem user) async {
    // Show confirmation dialog
    // Call service via provider
    // Refresh user list
    // Show success toast
  }
  
  // Similar handlers for demote, disable, enable
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] List displays users correctly
- [ ] Loading and error states work

---

### Step 8: Create Users Screen
**Goal**: Build main screen container with header and search

**Files to Create**:
- `lib/screens/users_screen.dart`

**Screen Structure**:
```dart
class UsersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('User Management'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Header bar with counter and invite button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Users: ${userStats.utilized} of ${userStats.capacity}'),
                FilledButton.icon(
                  icon: Icon(Icons.person_add),
                  label: Text('Invite Users'),
                  onPressed: userStats.remaining > 0 ? _showInviteDialog : null,
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or email...',
              ),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).state = value;
              },
            ),
            SizedBox(height: 24),
            
            // User list card
            Expanded(
              child: UserListCard(),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final stats = ref.read(userStatsProvider);
    showDialog(
      context: context,
      builder: (context) => InviteUsersDialog(
        remainingSlots: stats.remaining,
      ),
    );
  }
}
```

**Screen Elements**:
- Back button: Ghost-style, returns to dashboard
- User counter: "Users: X of 15"
- Invite button: Primary with icon, disabled at cap
- Search bar: Real-time filtering
- User list card: Scrollable list

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Screen renders correctly
- [ ] Search filters work
- [ ] Invite dialog opens

---

### Step 9: Add Routing and Navigation
**Goal**: Wire up routes and menu navigation

**Files to Modify**:
- `lib/main.dart` (add route)
- `lib/widgets/header/desktop_menu.dart` (add menu item)
- `lib/widgets/header/mobile_menu_sheet.dart` (add menu item)

**Routing** (in `main.dart`):
```dart
case '/manager/users':
  return MaterialPageRoute(
    builder: (context) => const UsersScreen(),
  );
```

**Desktop Menu** (in `desktop_menu.dart`):
```dart
PopupMenuItem(
  value: 'users',
  child: Row(
    children: [
      Icon(Icons.people),
      SizedBox(width: 8),
      Text(l10n.manageUsers),
    ],
  ),
),
```

**Mobile Menu** (in `mobile_menu_sheet.dart`):
```dart
ListTile(
  leading: Icon(Icons.people),
  title: Text(l10n.manageUsers),
  onTap: () {
    Navigator.pop(context); // Close sheet
    Navigator.pushNamed(context, '/manager/users');
  },
),
```

**Localization** (add to ARB files):
```json
{
  "manageUsers": "Manage Users",
  "@manageUsers": {
    "description": "Menu item for user management"
  }
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Desktop menu navigates correctly
- [ ] Mobile menu navigates correctly
- [ ] Route works from direct URL

---

### Step 10: Add Confirmation Dialogs
**Goal**: Add confirmation dialogs for destructive actions

**Files to Modify**:
- `lib/widgets/users/user_list_card.dart`

**Confirmation Dialogs**:

**Disable User**:
```dart
Future<bool> _showDisableConfirmation(BuildContext context, UserListItem user) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Disable User?'),
      content: Text('Are you sure you want to disable ${user.fullName}? They will no longer be able to access the system.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          child: Text('Disable'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Promote/Demote**:
```dart
Future<bool> _showRoleChangeConfirmation(BuildContext context, UserListItem user, bool isPromotion) {
  final action = isPromotion ? 'promote' : 'demote';
  final role = isPromotion ? 'Manager' : 'Employee';
  
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Change User Role?'),
      content: Text('Are you sure you want to $action ${user.fullName} to $role?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Confirm'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Confirmations appear before actions
- [ ] Cancel works correctly

---

### Step 11: Add Error Handling and Toast Notifications
**Goal**: Implement user feedback for all operations

**Files to Modify**:
- `lib/widgets/users/user_list_card.dart`
- `lib/widgets/users/invite_users_dialog.dart`

**Success Toasts**:
- "User promoted to Manager successfully"
- "User demoted to Employee successfully"
- "User disabled successfully"
- "User enabled successfully"
- "Users invited successfully"

**Error Handling**:
```dart
try {
  await service.promoteToAdmin(userId);
  ref.refresh(usersListProvider);
  _showSuccessToast('User promoted successfully');
} on AuthException catch (e) {
  _showErrorToast(e.message);
} catch (e) {
  _showErrorToast('An error occurred. Please try again.');
}
```

**Special Cases**:
- Self-modification: "You cannot modify your own account"
- Cap reached: "Cannot invite more users. Plan limit reached."
- Invalid emails: "No valid email addresses found"

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Success messages display
- [ ] Error messages display
- [ ] List refreshes after operations

---

### Step 12: Add Responsive Design
**Goal**: Optimize layout for mobile devices

**Files to Modify**:
- `lib/screens/users_screen.dart`
- `lib/widgets/users/user_list_item.dart`

**Mobile Adaptations**:
- Stack header elements vertically on narrow screens
- Make user list items more compact
- Adjust avatar sizes
- Make badges stack on very narrow screens
- Make invite dialog full-screen on mobile

**Example**:
```dart
Widget build(BuildContext context) {
  final isNarrow = MediaQuery.of(context).size.width < 600;
  
  return isNarrow 
    ? Column(children: [counter, inviteButton])
    : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [counter, inviteButton]);
}
```

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] Desktop layout looks good
- [ ] Mobile layout looks good
- [ ] Tablet breakpoint works

---

### Step 13: Add Localization
**Goal**: Make all strings translatable

**Files to Modify**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_he.arb`

**Strings to Add**:
```json
{
  "manageUsers": "Manage Users",
  "backToDashboard": "Back to Dashboard",
  "usersUtilized": "Users: {utilized} of {capacity}",
  "inviteUsers": "Invite Users",
  "inviteNewUsers": "Invite New Users",
  "searchByNameOrEmail": "Search by name or email...",
  "users": "Users",
  "active": "Active",
  "pending": "Pending",
  "disabled": "Disabled",
  "manager": "Manager",
  "employee": "Employee",
  "promoteToManager": "Promote to Manager",
  "demoteToEmployee": "Demote to Employee",
  "disable": "Disable",
  "enable": "Enable",
  "invitedOn": "Invited on {date}",
  "emailAddresses": "Email Addresses",
  "pasteOrTypeEmails": "Paste or type emails...",
  "separateWithSpaces": "Separate with spaces or commas ({slots} slots remaining)",
  "noSlotsRemaining": "No slots remaining",
  "role": "Role",
  "cancel": "Cancel",
  "confirm": "Confirm",
  "disableUserTitle": "Disable User?",
  "disableUserMessage": "Are you sure you want to disable {name}? They will no longer be able to access the system.",
  "changeRoleTitle": "Change User Role?",
  "changeRoleMessage": "Are you sure you want to {action} {name} to {role}?",
  "userPromotedSuccess": "User promoted to Manager successfully",
  "userDemotedSuccess": "User demoted to Employee successfully",
  "userDisabledSuccess": "User disabled successfully",
  "userEnabledSuccess": "User enabled successfully",
  "usersInvitedSuccess": "Users invited successfully",
  "cannotModifySelf": "You cannot modify your own account",
  "planLimitReached": "Cannot invite more users. Plan limit reached.",
  "noValidEmails": "No valid email addresses found"
}
```

**Hebrew Translations**: Add equivalent Hebrew strings to `app_he.arb`

**Verification**:
- [ ] Build completes: `flutter build web`
- [ ] No errors: `get_errors` tool
- [ ] English strings display correctly
- [ ] Hebrew strings display correctly
- [ ] RTL layout works for Hebrew

---

### Step 14: Integration Testing
**Goal**: Test complete user flows

**Test Scenarios**:

1. **View Users List**
   - Navigate to `/manager/users`
   - Verify user list loads
   - Verify counter displays correctly
   - Verify current user marked with "(you)"

2. **Search Users**
   - Enter search query
   - Verify list filters in real-time
   - Verify case-insensitive search
   - Clear search and verify list resets

3. **Invite Users**
   - Click "Invite Users" button
   - Enter multiple emails (comma-separated)
   - Select role
   - Submit invitation
   - Verify success toast
   - Verify list refreshes with new pending users
   - Verify counter updates

4. **Promote User**
   - Click actions menu on employee
   - Select "Promote to Manager"
   - Confirm dialog
   - Verify success toast
   - Verify role badge updates to "Manager"

5. **Demote User**
   - Click actions menu on manager
   - Select "Demote to Employee"
   - Confirm dialog
   - Verify success toast
   - Verify role badge updates to "Employee"

6. **Disable User**
   - Click actions menu on active user
   - Select "Disable"
   - Confirm dialog
   - Verify success toast
   - Verify status badge updates to "Disabled"
   - Verify user dimmed/grayed out
   - Verify counter updates (doesn't count disabled)

7. **Enable User**
   - Click actions menu on disabled user
   - Select "Enable"
   - Verify success toast
   - Verify status badge updates to "Active"
   - Verify counter updates

8. **Self-Modification Prevention**
   - Verify actions menu hidden on current user's row
   - Verify no way to modify own account

9. **Plan Cap Enforcement**
   - When at 15 users, verify "Invite Users" button disabled
   - Verify tooltip/message explains cap reached

10. **Error Handling**
    - Test with network disconnected
    - Verify error messages display
    - Verify graceful degradation

**Verification**:
- [ ] All scenarios pass
- [ ] No console errors
- [ ] UI remains responsive
- [ ] State management works correctly

---

## API Notes

### Missing Endpoints
The following endpoint is referenced in the UX but not yet documented in the API guide:
- `POST /api/users/resend-invitation` (mentioned in UX doc)

**Action Required**: Confirm this endpoint exists or adjust implementation to use alternative approach.

**Note**: The disable and enable endpoints are now documented and ready for implementation.

### API Considerations

**Rate Limiting**: The invite endpoint has a batch limit of 20 emails. Our plan limit is 15 users total, so we need to calculate remaining slots and enforce the lower limit.

**Refresh After Operations**: Most operations return `data: null` on success, so we need to refresh the user list after each operation to get updated data.

**Error Messages**: Use the `message` field from API responses for user-facing error messages.

---

## Business Rules Checklist

- [x] Maximum 15 users (active + pending, excluding disabled)
- [x] Managers cannot modify their own account
- [x] Disabled users don't count toward cap
- [x] Pending users count toward cap
- [x] Actions menu hidden for current user's row
- [x] Invite button disabled when cap reached
- [x] Email deduplication (case-insensitive)
- [x] Email format validation
- [x] Auto-trim invites to remaining slots
- [x] Confirmation dialogs for destructive actions
- [x] Administrator-only access (roleId: 1)

---

## Localization Requirements

- [x] All user-facing strings in ARB files
- [x] English translations
- [x] Hebrew translations
- [x] RTL support for Hebrew
- [x] Date formatting respects locale
- [x] Pluralization for user counts

---

## Final Verification Checklist

Before marking this module complete:

- [ ] All routes work (desktop, mobile, direct URL)
- [ ] All API integrations work
- [ ] All user actions work (promote, demote, disable, enable, invite)
- [ ] Search and filtering work
- [ ] Confirmations appear for destructive actions
- [ ] Success/error toasts display
- [ ] Loading states display during API calls
- [ ] Error states display when APIs fail
- [ ] Responsive design works on all screen sizes
- [ ] Localization works (English + Hebrew)
- [ ] RTL layout works for Hebrew
- [ ] No console errors or warnings
- [ ] User cannot modify their own account
- [ ] Plan cap enforcement works
- [ ] Counter updates correctly after operations
- [ ] List refreshes after operations
- [ ] Back button returns to dashboard

---

## Notes for Future Enhancements

1. **Resend Invitation**: UX doc mentions "Add resend invitation" - needs API endpoint and implementation
2. **Bulk Actions**: Consider adding checkboxes for bulk promote/disable operations
3. **User Details View**: Could add detailed user profile view with activity history
4. **Audit Log**: Track all user management actions for compliance
5. **Export**: Add ability to export user list to CSV
6. **Advanced Search**: Add filters for role, status, etc.
7. **Pagination**: If user list grows beyond 100, implement pagination

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-16  
**Status**: Ready for Implementation
