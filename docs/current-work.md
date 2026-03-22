# Current Work & TODO

## Currently Working On

**Bug: Backend unavailable exposes raw URL in error messages**
- `ApiService` lets `ClientException` (contains URL) bubble up unhandled
- `UserListCard._buildErrorState` renders `error.toString()` directly
- Fix: add `NetworkException` wrapper in `ApiService` + show generic localized message in error state

## TODO (Backlog)

## report bugs (pending)

* onboardin
* when logout api gets 401 we got a nasty console error :
errors.dart:274 Uncaught (in promise) DartError: Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.

* Missing invite users option after signup - we need to have a quick onboarding flow to allow manager invite users
[x] Invite users modal does not close on submit - after adding a user it should be closed
* New expense modal spacing hides Continue button - the titles and back button takes too much of the screen

* Finish button misaligned ,should be left on LTR, and below the image.

* Missing rejection reason field for manager - new feature
* editing and expense - the expand button on the expense doesnt have a mouse pointer on hover, we would like that on desktop - when a user clicks on the image itself, the entire image will have a hint that its explandable - and when you click on it it will expand.
* Empty state tables not collapsing/expanding correctly - need to explain this behaviour
* when i disabled a user i dont see him on the users list
[x] user managment  - on any command, if you got an error - we want to see the error
* when i submit an expense and AI did detect , i want to click on the finish button but i cant understand the the category is mandatory - maby when i hit done but the category is empty, move the category a bit so i figure it out.
* when backend is not available - we are showing a bad error revealing backend url - we just need to show a general "temporary internet error - please check your connection" or something like that.
[x] when adding a user that belongs to another company - show explicit inline error with conflicting emails marked red

* onboarding bug - i listed a new company, completed otp with 123456, then i was landing on the dashbaord but i got the info of the previous company. maby we need to make sure we delete any token stored , while we are in the onboarding process.

## general environment


- [ ] create a real privacy policy
- [ ] create a real terms and conditions
- [ ] need to replace the icon of the webpage
- [ ] when an api fails it keeps calling it on a loop - if you get 400/500 - stop with an error.
- [ ] login with google
- [ ] get zehut for customers in IL
- [ ] we need to be able to impersonate a user
- [ ] we need a admin view to see compaines usage
- [ ] we need to connect google analytics / GTM
- [ ] we need to translate better to hebrew
- [ ] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/post-login-deep-linking-spec.md

## submit an expense


## user expenses report

- [ ] the ai strike through when ai didnt recognize the image is not clear - add explicit warning

## manager expenses report

- [ ] build the spend overview widget for manager and employee spend-overview-spec.md

## management screens
- [ ] we need to configure which categories are available
- [ ] we need to be able to delete pending users


## processes & other stuff

- [ ] spend history - user
- [ ] billing area

---
