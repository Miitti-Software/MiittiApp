# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### To Be Added

- Finnish translations of text
- Custom emojis and activities
- Collection and storage of relevant data
- Use Performance Monitoring, Test Lab, App Distribution, Crashlytics and Analytics
- Testing of most major operations such as signing in, signing up, creating and joining a miitti, viewing major pages and deleting account.

### To Be Changed

- Modernize the UI of all screens
- Make sure people who have originally signed up with mobile numbers retain access to their accounts
- Simplify `MiittiUser` class and modify Firestore database accordingly
- Refactor UI components to use `miitti_theme.dart`
- Rename strings role-wise instead of content-wise
- Refactor `firestoreService` functions from function after `updateUser` till function before `_wait`
- Send a new email confirmation email after a couple of days in order to counteract temporary email accounts.
- Compose Mitti icons on the map from a background gradient and an emoji - not png files

### To Be Fixed

- Make it impossible to participate in an event as an anonymous user -> finish your profile prompt

### To Be Removed

- Admin IDs of non-contributors
- `AuthProvider` class will become redundant once `AuthService` has been fully implemented

## [2.0.2] - 2024-12-04

### Added

- "Read by all" indicators to chats
- Color-coded internal notifications (orange for requests and joins, and pink for messages)
- Map tile caching to improve performance and save bandwidth
- An invite button to activity details, which now enables sending invitations after the creation of an activity
- A "mark as passed" button, which can be used to archive past activities and hide them from the map without deleting them
- A switch for toggling location permissions on and off on the settings page
- The ability to change the start time of an activity by clicking on the calendar icon in activity details

### Fixed

- Push notifications switch now reliably toggles permissions with requests if permission has not previously been given
- A bug that would crash the app upon opening certain types of push notifications
- A bug that allowed users to access the open app without unlocking their device
- A bug displaying old activities on the map when clicking on the chats
- Ensured that illegitimate names such as "null" cannot be used
- Various other bugs having to do with notifications and GUI behavior

### Changed

- Made QA-cards optional when creating an account
- Changed Finnish to be the selected default language
- Made profile pictures clickable in activities
- Refactored the profile screen to load the given user in a better way

### Removed

- Massive amounts of old, unused code

## [2.0.1] - 2024-09-30

Patches to refactored app

## [2.0.0] - 2024-09-30

Finished full refactoring of the app


## [1.5.7] - 2024-07-25

Refactoring

### Added

- Firebase Remote Config for changing, modifying and rapidly experimenting with app text, UI and content without always having to release new updates in app stores
- Language setting in `settings.dart`
- Language-based loading of Remote Config values (multi-language support)
- A more robust routing solution using [GoRouter](https://pub.dev/packages/go_router) for deep linking and redirecting support as well as for a more uniform routing interface in code
- Profile pictures are compressed and smaller thumbnails are created for each new one
- Deep links to activities

### Fixed

- Account removal process
- Refactored widgets role-wise so that they can be reused based on their puprose

### Changed

- The Google account to be signed in with must be separately selected each time so that people (developers) can easily switch between accounts.
- Refactored `AuthService` sign-in methods to be parameterless to reduce dependencies, encapsulate backend logic and so enhance reusability and return boolean futures in order to shift UI logic to the widgets using them.
- All state management including `state_providers.dart` are now under `lib/state`.
- Refactored all user-related variables from `AuthService` and `FirebaseService` to `UserState` and `UserData` respectively in `user.dart` in order to avoid cross-dependencies.
- Refactored all screens and UI components for clarity, reduced dependencies, centralized specification and loading of content and constants as well as overall future-proofness.
- Refactored `CompleteProfileOnboard` into multiple separate screens, each interacting with `UserData`, which is saved to Firestore as a `MiittiUser` upon completion of the profile. Fixes back navigation and information persistence along with making it significantly easier to maintain the pages in the future. 
- Anonymous profiles can be deleted as well
- Deleting a profile removes the profile from all requests, participant lists and -infos as well as immediately archives the miittis created by them
- Added activity `endTime` as a query condition to filter out past miittis but keep them in firestore

### Removed

- `ScreenUtilInit` widget and dependencies in order to create a uniform user experience across devices.
- Sign-in via a phone number due to redundancy and potential extra costs.
- `_buildAuthScreen` method from `MiittiApp` due to becoming redundant after GoRouter was implemented

## [1.5.6] - 2024-07-08

Added development, staging and production environments to enable risk-free offline development, support testing and avoid polluting the real database as well as other accidents. This is documented in more detail in [NOTES.md](NOTES.md). 

### Added

- New Firebase projects called MiittiAppDev and MiittiAppStaging to create development and staging/testing/standardized development environments.
- Android app flavors for different build configurations to facilitate different environments.
- Different Firebase configuration files in `envs` corresponding to the development, staging and production environments.
- `google-services.json` files corresponding to above configurations.
- `UpdateScreen` and `MaintenanceBreakScreen` to encourage or force updates or to even fully lock down the app for temporary backend maintenance

## [1.5.5] - 2024-06-27

Currently published app is version at the time of adding this is 1.5.4. Hence, starting this from 1.5.5. Restored app to working confition where one can sign in without it freezing.

### Added

- This CHANGELOG.md in order to make it easier to track changes to this repository and learn how the code works. Its purpose is to make collaboration easier by encouraging contributors to share their reasoning behind their additions, changes, deprecations, removals, fixes and security patches as well as to provide space for expanding more on the relevant details of each commit that other contributors should be aware of. 
- Custom `ThemeData` object in `miitti_theme.dart` for configuring the colors and fonts based on their roles instead of their values so that the app theme can be customized easily from one place.
- New activities in `constants.dart`. 

### Fixed

- `return` keyword was added to the `t()` function in `app_texts.dart` to fix red screen upon signing in.
- Various `mounted` checks to fix freezing resulting from calls to asynchronous methods.
- Fixed parsing MiittiUser lists, maps and time
- Modified error management in `app_text.dart` to not crash app in debugmode if key is not found

### Changed

- `MiittiUser` `userStatus` timestamp property that could easily be confused with `UserStatusInActivity` was changed to `lastActive` to more accurately reflect its purpose and role in determining the user's status. 
- Lowered `AnonymousDialog` delays to 10ms avoid freezing from fast navigation. 

### Removed

- Unused imports