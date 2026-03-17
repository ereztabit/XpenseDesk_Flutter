# Pull-to-Refresh Behavior

## Goal

On mobile, users should be able to refresh the current screen by pulling downward from the top of the page, using the standard mobile pull-to-refresh interaction.

## Expected User Experience

- The behavior is mobile-only.
- When the user is at the top of a scrollable screen and drags down, the app should show a refresh indicator.
- If the drag passes the refresh threshold and the user releases, the current screen reloads its data.
- The refresh should update only the current page's data, not reload the entire app.
- This should feel like the default pattern users expect in native mobile apps.

## Scope

This behavior applies to screens that:

- have vertically scrollable content
- display server-backed or refreshable data
- need a manual way for the user to re-fetch current information

## Non-Goals

- No pinch gesture support. This is not a zoom interaction.
- No full application restart or browser-style page reload.
- No desktop-specific refresh gesture.

## Functional Requirements

- The refresh gesture should only trigger when the scroll position is already at the top.
- Pulling down while mid-list should continue normal scrolling and should not trigger refresh.
- The screen should call its existing reload or re-fetch logic.
- While refresh is in progress, the UI should show a loading indicator consistent with platform expectations.
- Repeated refresh attempts should be ignored while a refresh is already running.
- If refresh fails, the user should see the existing error handling pattern for that screen.

## Flutter Implementation Direction

- Prefer Flutter's built-in `RefreshIndicator` for Material screens.
- Wrap the primary vertical scrollable content so the refresh gesture works consistently.
- Connect `onRefresh` to the relevant provider invalidation or screen reload method.
- For short content that does not naturally scroll, ensure the page still supports pull-to-refresh by using an always-scrollable physics configuration where appropriate.

## Acceptance Criteria

- On mobile, pulling down from the top of a supported screen shows a refresh indicator.
- Releasing after crossing the threshold refreshes the current screen's data.
- The page does not perform a full app reload.
- The interaction does not affect desktop behavior.
- The gesture works on both Android and iOS targets.