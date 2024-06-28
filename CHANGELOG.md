# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### To Be Added

- Dynamic loading of texts and activities from Firebase
- Multi-language support
- Small and large, compressed versions of profile pictures
- Collection and storage of relevant data
- Use Firebase Remote Config, Performance Monitoring, Test Lab and Crashlytics

### To Be Changed

- Modernize the UI of all screens
- Simplify `MiittiUser` class and modify Firestore database accordingly
- Refactor UI components to use `miitti_theme.dart`
- Rename strings role-wise instead of content-wise
- Refactor `firestoreService` functions from function after `updateUser` till function before `_wait`

### To Be Fixed

- Google Sign-In so that users with pre-existing accounts will not appear as anonymous users
- Make it impossible to participate in an event as an anonymous user -> finish your profile prompt

### To Be Removed

- Admin IDs of non-contributors
- `AuthProvider` class will become redundant once `AuthService` has been fully implemented

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