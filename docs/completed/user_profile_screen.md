# User Profile Screen

## Overview

The User Profile screen allows authenticated users (both managers and employees) to view and edit their personal information. The screen displays user details fetched from the backend API and enables users to update their full name and language preference.

## Screen Access

**Routes:**
- `/manager/profile` - Accessed by manager users
- `/employee/profile` - Accessed by employee users

Both routes point to the same `ProfileScreen` widget, as the functionality is identical for both user roles.

**Navigation:**
Users access the profile screen by clicking "Profile" in the header menu (both desktop avatar menu and mobile menu sheet).

## Data Model

### UserInfo Model

The `UserInfo` model represents the user's profile data:

```dart
class UserInfo {
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final String companyName;
  final int languageId;  // 1 = English, 2 = Hebrew
}
```

### Language Mapping

The system uses integer language IDs that map to locale codes:

| languageId | Locale Code | Language |
|------------|-------------|----------|
| 1          | en          | English  |
| 2          | he          | Hebrew   |

## API Integration

### GET User Data

**Endpoint:** `GET /api/users/me`

**Authentication:** Bearer token (session token)

**Response:**
```json
{
  "data": {
    "email": "user@example.com",
    "fullName": "John Doe",
    "roleId": 2,
    "status": "Active",
    "companyName": "Acme Corp",
    "languageId": 1
  }
}
```

The screen loads user data on initialization using the existing `AuthService.getUserInfo()` method, which automatically includes the session token.

### PUT Update User Profile

**Endpoint:** `PUT /api/users/update-details`

**Authentication:** Bearer token (session token)

**Request Body:**
```json
{
  "fullName": "string",
  "languageId": 1
}
```

**Success Response:** 200 OK with updated user data

**Error Response:** 4xx/5xx with error details

## Screen Layout

The profile screen uses a two-card layout matching the design system:

### 1. Profile Card

Contains user identity information:

- **Icon:** Person icon with "Profile" label
- **Name Field:** Editable text input for full name
- **Email Field:** Read-only text display (non-editable)

### 2. Settings Card

Contains user preferences:

- **Icon:** Settings icon with "Settings" label
- **Language Field:** Dropdown selector with English/Hebrew options

### 3. Actions

- **Back to Dashboard:** Navigation link at the top
- **Save Changes:** Button at the bottom right to persist changes

## Field Validation

### Full Name

**Validation Rules:**
- **Maximum length:** 50 characters
- **Allowed characters:** Letters (a-z, A-Z), spaces, and hyphens (-)
- **Prohibited:** Numbers (0-9), special symbols except hyphen

**Regex Pattern:** `^[a-zA-Z\s-]{1,50}$`

**Error Messages:**
- If name contains numbers: "Name cannot contain numbers"
- If name contains invalid symbols: "Name can only contain letters, spaces, and hyphens"
- If name exceeds 50 characters: "Name must be 50 characters or less"
- If name is empty: "Name is required"

### Email

The email field is read-only and cannot be edited. It displays the current email from the API.

### Language

No validation required. User selects from a dropdown of available options (English or Hebrew).

## Data Flow

### Loading User Data (Screen Initialization)

1. User navigates to profile screen
2. Screen reads current `UserInfo` from `userInfoProvider`
3. `TextEditingController` is populated with current `fullName`
4. Language dropdown is set to current `languageId` (1 or 2)
5. Email is displayed as read-only text

### Editing Data

1. User modifies the full name in the text field
2. User selects a different language from dropdown
3. **Important:** UI locale does NOT change during editing (only on save)
4. Form validation runs on the name field

### Saving Changes

1. User clicks "Save Changes" button
2. Form validation executes:
   - If validation fails: Display error messages, do not proceed
   - If validation passes: Continue to API call
3. `AuthService.updateUserProfile(fullName, languageId)` is called
4. API request sent: `PUT /api/users/update-details` with bearer token
5. **On Success:**
   - Update local `userInfoProvider` state with new data
   - Update `localeProvider` to match the saved languageId
   - Display success message (e.g., "Profile updated successfully")
   - UI switches to the selected language
6. **On Error:**
   - Display error alert with message from API
   - Keep existing data unchanged
   - User can retry or cancel

## State Management

### Providers Used

**userInfoProvider** (UserInfoNotifier)
- Stores the current user's profile data
- Initialized on login via `loadFromSession()`
- Updated after successful profile save via `updateProfile(userInfo)`

**localeProvider** (LocaleNotifier)
- Stores the current UI locale (Locale('en') or Locale('he'))
- Updated ONLY after successful profile save (not on dropdown change)

**authServiceProvider** (AuthService)
- Handles API calls for fetching and updating user data
- Manages session token for authentication

### State Update Flow

```
User clicks Save
    ↓
Validate form
    ↓
AuthService.updateUserProfile() → API call
    ↓
Success?
    ↓ Yes
UserInfoNotifier.updateProfile() → Update user state
    ↓
LocaleNotifier.setLocale() → Update UI language
    ↓
Show success message
```

## Implementation Details

### Service Layer

**ApiService.put():**
- New method added to handle HTTP PUT requests
- Follows same pattern as `get()` and `post()` methods
- Accepts optional `authToken` parameter for bearer authentication

**AuthService.updateUserProfile():**
```dart
Future<UserInfo> updateUserProfile(String fullName, int languageId) async {
  final sessionToken = await getSessionToken();
  
  final response = await _apiService.put(
    '/api/users/update-details',
    {
      'fullName': fullName,
      'languageId': languageId,
    },
    authToken: sessionToken,
  );
  
  return UserInfo.fromJson(response['data']);
}
```

### Form State Management

The screen uses `ConsumerStatefulWidget` to integrate Riverpod with form state:

- `GlobalKey<FormState>` for form validation
- `TextEditingController` for the name field
- Local `int` variable for selected languageId (tracks dropdown selection)
- `initState()` populates controllers with current user data

### Language-Locale Conversion

Helper methods convert between languageId and Locale:

```dart
Locale _languageIdToLocale(int languageId) {
  return languageId == 1 ? Locale('en') : Locale('he');
}

int _localeToLanguageId(Locale locale) {
  return locale.languageCode == 'en' ? 1 : 2;
}
```

### Validation Implementation

Uses `TextFormField.validator` property:

```dart
TextFormField(
  controller: _fullNameController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length > 50) {
      return 'Name must be 50 characters or less';
    }
    final validNameRegex = RegExp(r'^[a-zA-Z\s-]+$');
    if (!validNameRegex.hasMatch(value)) {
      if (RegExp(r'\d').hasMatch(value)) {
        return 'Name cannot contain numbers';
      }
      return 'Name can only contain letters, spaces, and hyphens';
    }
    return null;
  },
)
```

## Error Handling

### Network Errors
- API timeout or connection failure
- Display user-friendly error message
- Keep existing data in form (allow user to retry)

### Validation Errors
- Display inline error messages below invalid fields
- Prevent API call until validation passes

### Authentication Errors
- If session token is invalid (401 response)
- Log user out and redirect to login screen
- Follows existing auth error handling pattern

## Localization

All user-facing text uses localization keys from ARB files:

- `myProfile` - "My Profile" / "הפרופיל שלי"
- `settings` - "Settings" / "הגדרות"
- `name` - "Name" / "שם"
- `email` - "Email" / "אימייל"
- `language` - "Language" / "שפה"
- `saveChanges` - "Save Changes" / "שמור שינויים"
- `backToDashboard` - "Back to Dashboard" / "חזור לדשבורד"

## Security Considerations

1. **Bearer Token Authentication:** All API calls include the session token
2. **Email Immutability:** Email cannot be changed (prevents account hijacking)
3. **Input Validation:** Name field is validated to prevent injection attacks
4. **Session Management:** Invalid tokens trigger logout and redirect to login

## Future Enhancements

Potential additions to the profile screen:

- Profile photo upload
- Password change functionality
- Additional user preferences (notifications, theme)
- Role-specific fields (different editable fields for managers vs employees)
- Account deactivation option
- Two-factor authentication settings

---

## Implementation Steps

### **Step 1: Update UserInfo Model**

**File:** `lib/models/user_info.dart`

**Changes:**
- Add `languageId` field to the `UserInfo` class (type: `int`)
- Update `fromJson` factory to parse `languageId` from API response
- Update `toJson` method to include `languageId` in serialization
- Add `languageId` to constructor parameters

**What to verify:**
- Model compiles without errors
- `languageId` defaults to 1 if not provided in JSON (for backward compatibility)
- Run `flutter build web` to verify no compilation errors

---

### **Step 2: Add PUT Method to ApiService**

**File:** `lib/services/api_service.dart`

**Changes:**
- Add new `put()` method following the same pattern as existing `get()` and `post()` methods
- Method signature: `Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {String? authToken})`
- Include bearer token in Authorization header if provided
- Set Content-Type to application/json
- Parse response body as JSON
- Handle HTTP errors appropriately

**What to verify:**
- Method compiles
- Follows same error handling pattern as other methods
- Headers structure matches existing methods
- Run `flutter build web` to verify no compilation errors

---

### **Step 3: Add Update Method to AuthService**

**File:** `lib/services/auth_service.dart`

**Changes:**
- Add `updateUserProfile(String fullName, int languageId)` method
- Get session token using `getSessionToken()`
- Call `_apiService.put('/api/users/update-details', body, authToken: sessionToken)`
- Request body: `{'fullName': fullName, 'languageId': languageId}`
- Return `UserInfo.fromJson(response['data'])`
- Handle errors (throw exceptions for network/auth failures)

**What to verify:**
- Method uses correct endpoint: `/api/users/update-details`
- Bearer token authentication is included
- Returns updated `UserInfo` object
- Run `flutter build web` to verify no compilation errors

---

### **Step 4: Add Update Method to UserInfoNotifier**

**File:** `lib/providers/auth_provider.dart`

**Changes:**
- Add `updateProfile(UserInfo userInfo)` method to `UserInfoNotifier` class
- Method sets `state = userInfo` to update local state
- Keep it simple - just update the state with the new user info from API

**What to verify:**
- Method updates provider state
- Can be called from UI layer
- Follows existing provider patterns in the file
- Run `flutter build web` to verify no compilation errors

---

### **Step 5: Create ProfileScreen**

**File:** `lib/screens/profile_screen.dart` (new file)

**Structure:**
- Create `ConsumerStatefulWidget` named `ProfileScreen`
- State class with:
  - `final _formKey = GlobalKey<FormState>()`
  - `final _fullNameController = TextEditingController()`
  - `int _selectedLanguageId = 1` (local state for dropdown)
  - `bool _isLoading = false` (for save button state)

**initState():**
- Get current `UserInfo` from `ref.read(userInfoProvider)`
- Initialize `_fullNameController.text` with `userInfo.fullName`
- Initialize `_selectedLanguageId` with `userInfo.languageId`

**build() method structure:**
- Scaffold with AppBar ("Back to Dashboard" leading button)
- SingleChildScrollView body with padding
- Two Card widgets:
  - **Profile Card:** Icon + "Profile" title, name TextFormField (editable), email text widget (read-only)
  - **Settings Card:** Icon + "Settings" title, language DropdownButtonFormField
- Save button (ElevatedButton) aligned to bottom right

**Name validation:**
- Required field check
- Max 50 characters
- Regex: `^[a-zA-Z\s-]+$`
- Specific error messages for numbers vs other invalid characters

**Language dropdown:**
- `DropdownButtonFormField<int>`
- Items: `[DropdownMenuItem(value: 1, child: Text('English')), DropdownMenuItem(value: 2, child: Text('Hebrew'))]`
- onChanged updates `_selectedLanguageId` only (doesn't change locale)

**Save handler (_handleSave):**
1. Validate form: `if (!_formKey.currentState!.validate()) return;`
2. Set loading state: `setState(() => _isLoading = true)`
3. Get auth service: `final authService = ref.read(authServiceProvider)`
4. Call API: `final updatedUser = await authService.updateUserProfile(_fullNameController.text, _selectedLanguageId)`
5. Update provider: `ref.read(userInfoProvider.notifier).updateProfile(updatedUser)`
6. Update locale: `ref.read(localeProvider.notifier).setLocale(_selectedLanguageId == 1 ? Locale('en') : Locale('he'))`
7. Show success message via SnackBar
8. Error handling: try-catch with error alert
9. Clear loading state in finally block

**What to verify:**
- Screen compiles
- All widgets properly structured
- Validation logic works
- Loading states handled
- Error handling in place
- Run `flutter build web` to verify no compilation errors

---

### **Step 6: Add Routing**

**File:** `lib/main.dart`

**Changes:**
- In `onGenerateRoute` callback, add two new cases:
  - `case '/manager/profile':`
  - `case '/employee/profile':`
- Both return: `MaterialPageRoute(builder: (context) => const ProfileScreen())`
- Add import: `import 'package:xpensedesk_flutter/screens/profile_screen.dart';`

**What to verify:**
- Routes compile
- Navigation from menu works
- Both routes point to same screen
- Import path is correct
- Run `flutter build web` to verify no compilation errors

---

### **Step 7: Integration Testing**

**Manual testing checklist:**

1. **Load screen:**
   - Navigate to profile from header menu
   - Verify name, email, language load correctly
   - Verify email is read-only (not editable)

2. **Name validation:**
   - Try empty name → Should show error
   - Try name with numbers → Should show "cannot contain numbers"
   - Try name with symbols like @ # $ → Should show "only letters, spaces, hyphens"
   - Try 51+ character name → Should show "must be 50 characters or less"
   - Try valid name → Should accept

3. **Language selection:**
   - Change dropdown to different language
   - Verify UI language does NOT change yet
   - Verify dropdown value updates

4. **Save functionality:**
   - Change name and language
   - Click Save Changes
   - Verify loading state shows during API call
   - Verify success message appears
   - Verify UI language changes AFTER save
   - Verify local state updated (check provider)

5. **API verification:**
   - Check network tab: `PUT /api/users/update-details`
   - Verify request body: `{"fullName": "...", "languageId": 1}`
   - Verify bearer token in Authorization header

6. **Persistence:**
   - Refresh page or navigate away and back
   - Verify changes persisted from API

7. **Error handling:**
   - Test with network offline → Should show error
   - Test with invalid token → Should handle auth error

---

**Implementation Order:**
1. → Model (data structure)
2. → API layer (HTTP communication)
3. → Service layer (business logic)
4. → State management (app state)
5. → UI screen (user interface)
6. → Routing (navigation)
7. → Testing (verification)

**Build after each step:** Run `flutter build web` to verify no compilation errors before proceeding to the next step.

**Wait for confirmation:** Do not proceed to the next step until explicitly instructed.
