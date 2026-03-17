# Post-Login Deep Linking

## Goal

When an unauthenticated user opens a protected deep link from outside the app, the app should redirect the user to login and then return them to the exact page they originally requested after authentication succeeds.

## Problem This Solves

Right now, a user can try to open a direct link to a protected screen such as a dashboard report, but after being forced through login, the app may lose the original target route and send the user to a generic default screen instead.

That creates a broken deep-linking flow.

## Expected User Experience

- A user opens a protected URL directly from outside the app.
- If the user is not authenticated, the app redirects to login.
- The originally requested route is stored.
- After successful login, the app navigates to the exact route the user originally requested.
- If the route is invalid or no longer allowed for that user, the app falls back to the correct default landing page for that role.

## Scope

This task covers:

- direct navigation to protected routes from outside the app
- preserving the intended route through the login flow
- restoring that route after successful authentication

This task does not cover:

- public routes that do not require authentication
- permission redesign beyond normal role-based access checks
- unrelated navigation cleanup

## Functional Requirements

- Detect when an unauthenticated user attempts to access a protected route.
- Redirect that user to the login screen.
- Preserve the full intended destination, including path and relevant query parameters.
- After login, navigate to the preserved route.
- Clear the preserved route once it has been used.
- If login fails or is cancelled, do not navigate to the protected target.
- If the stored route is not valid for the authenticated user, fall back safely to the correct role-based home screen.

## Example Flow

1. User opens a link to a manager report.
2. App sees the route requires authentication.
3. User is redirected to login.
4. Login succeeds.
5. App restores the original report route.
6. User lands in the requested report instead of a generic dashboard.

## Implementation Direction

- Capture the requested route before redirecting to login.
- Store it in a short-lived auth redirect state.
- After successful login and session bootstrap, resolve and navigate to the stored route.
- Keep role and authorization checks in place before final navigation.

## Acceptance Criteria

- Opening a protected deep link while logged out redirects to login.
- After successful login, the user lands on the originally requested protected route.
- Query parameters needed by the destination screen are preserved.
- Invalid or unauthorized targets fall back to a safe default route.
- The flow works on web refresh and direct URL entry.