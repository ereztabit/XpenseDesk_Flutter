# Current Work & TODO

## Currently Working On

- manager/Employee dashboard does not auto-refresh

## TODO (Backlog)

## report bugs (pending)

* onboardin
* when logout api gets 401 we got a nasty console error :
errors.dart:274 Uncaught (in promise) DartError: Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.

* Missing invite users option after signup - we need to have a quick onboarding flow to allow manager invite users
* Invite users modal does not close on submit - after adding a user it should be closed
* New expense modal spacing hides Continue button - the titles and back button takes too much of the screen

* Finish button misaligned ,should be left on LTR, and below the image.
* Manager and employee edit screens inconsistent - there should have been only one widget for new , update and view - consolidate them - the new expense is the most recent and rich
* Missing rejection reason field for manager - new feature
* Empty state tables not collapsing/expanding correctly - need to explain this behaviour
* No error message on failed expense deletion- the user tried to delete an expense that was already approved.
* when i disabled a user i dont see him on the users list
* user managment  - on any command, if you got an error - we want to see the error
* expense screen - remove the ai badge below the image and also the one with the strike through
* when i submit an expense and AI didnt detect the details i want to see a warning message on top of the fields.
* when i submit an expense and AI did detect , i want to click on the finish button but i cant understand the the category is mandatory - maby when i hit done but the category is empty, move the category a bit so i figure it out.
* when backend is not available - we are showing a bad error revealing backend url - we just need to show a general "temporary internet error - please check your connection" or something like that.
* when adding a user that belongs to another company we get this error -
{
    "success": false,
    "message": "Email already belongs to another company",
    "errorCode": "UsersInviteEmailBelongsToAnotherCompany",
    "data": {
        "email": "arlib1988@gmail.com"
    }
},
show an explicit error explaning we cannot join this user to this company


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
* AI icon text unclear in step 2 - need to refine it

## user expenses report

- [ ] the ai strike through when ai didnt recognize the image is not clear - add explicit warning

## manager expenses report

- [ ] build the spend overview widget for manager and employee spend-overview-spec.md

## management screens
- [ ] we need to configure which categories are available


## processes & other stuff

- [ ] spend history - user
- [ ] billing area

---
