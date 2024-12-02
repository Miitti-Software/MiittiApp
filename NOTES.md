# Notes

Notes, remarks, tips & tricks, links to useful resources and other miscellaneous documentation on broader topics, technologes and development in general. The idea is for this to be a great place for new developers to quickly browse through and occasionally return to in order to quickly get up to speed on a new area of development. This is the most up-to-date place for documentation and therefore overrides all other sources. 

## Code Guidelines

**Motivation:**

All code should be maximally reusable, efficiently modifiable and understandable. The relationships between pieces of code should be obvious and all interfaces should be as coherent and universal as possible for efficient use.

Minor UI changes such as changing colors, fonts and the shape, spacing and content of cards and list items should be doable entirely by manipulating constants and atomic components alone, whereas layout changes can be done by modifying screens and both UI and logic of larger processes such as registration and creating Miittis can be tweaked in a single location separately from everything else.

**General guidelines:**

- Default to using Effective Dart (https://dart.dev/effective-dart)
- Name variables, functions and classes descriptively according to Effective Dart guidelines
    - Ideally, the name would communicate as much as a comment would
    - Avoid verbs in widget names for declarative clarity
    - Use verbs for function names
    - Prioritise clarity over conciseness but aim to be economical
- Comment your code descriptively above non-trivial class and function definitions
    - Explain the purpose and role of the class/function
    - Clarify the intended context of use
    - Define and elaborate upon the input parameters and output
    - Use doc comments (https://dart.dev/effective-dart/documentation#doc-comments) for major APIs
    - Prioritise clarity over conciseness but aim to be economical
    - Use TODOs (https://dart.dev/tools/linter-rules/flutter_style_todos)
- Separate UI components and business logic functions
    - All interaction components should have (a) parameter(s) for functions to be executed upon actions on it instead of pre-defined ones so that the components remain widely applicable
- Create well defined UI components where only their content changes
    - E.g. a button should take as parameters only: text and/or an icon, color and a function to be executed on tap. Size, shape and anything else related to their form should be rigidly defined within and not be subject to change via outside influence as this would require the code to be edited in multiple places upon changes
- UI dependencies should flow in a single direction only: constants → components → screens/functionalities (where right of arrow depends on the left of arrow)
- Never hardcode constants outside the constants file
    - All UI component parameters should be defined in the constants file to avoid having to change the code in multiple places
    - Strings should be loaded from a database for easy changeability and translatability
- Use GitHub flow branching strategy (https://docs.github.com/en/get-started/using-github/github-flow) where branches are created on a feature basis with short, descriptive names and merged to main via pull requests after completion and review.
- Git commit and push often
    - Every time you step away from your computer without errors and warnings is a great time to commit and push to feature branch. This significantly reduces the risk of irreversible damage and shows others how much progress is being made, where, and at what pace, thus significantly aiding in coordination.
- Remove redundant code (after first committing!) if nothing breaks
- Pull requests must not have any errors
- Document your changes and rationales for them in the changelog

## Project structure

- **main.dart** serves as the entrypoint to the app
- **constants** folder contains the app theme and default values for [Remote Config](https://firebase.google.com/docs/remote-config) resources such as static app text
- **envs** contains Firebase options and potentially other files corresponding to each [deployment environment](https://en.wikipedia.org/wiki/Deployment_environment)
- **functions** contains functions and utilities not directly related to backend services
- **models** contains templates for data objects as well as other abstract classes, which are meant to be instantiated elsewhere in the code
- **routing** contains all routing-related logic
- **screens** contains larger, singular UI views and templates composed of atomic widgets
- **services** contains all backend related classes and functions such as the interfaces for communicating with Firebase services and local storage and settings
- **Widgets** contains small and potentially repetitive, "atomic" UI elements used to construct higher level widgets and screens

## Flutter

Perhaps the best resource for learning Flutter is its documentation: https://docs.flutter.dev/

Reading list:
1. https://flutter.dev/
2. https://flutter.dev/learn
3. https://dart.dev/language
4. https://dart.dev/effective-dart
5. https://dart.dev/language/async
6. https://docs.flutter.dev/get-started/install
7. https://docs.flutter.dev/ui
8. https://docs.flutter.dev/resources/architectural-overview
9.  https://docs.flutter.dev/data-and-backend/state-mgmt/intro
10. https://docs.flutter.dev/ui/navigation

## Development, staging and production environments

The broad idea of different [deployment environments](https://en.wikipedia.org/wiki/Deployment_environment) is to have the same code interact with different data depending on where it is currently in the development cycle. The development version can interact with mock data separated from the real database, whereas the production version operates with real user data. This separation allows for freely testing different kinds of data without having to worry about accidents or pollution of the real database. Furthermore, it can be cheaper to not have to call the real database and less confusing for our users when we do not have to worry about accidentally displaying mock data in our app. 

The three development, staging and production environments are currently configured according to [this article](https://medium.com/flutter-community/using-different-environments-with-firebase-and-flutter-aa4fb0e0dd52) so that the `envs` folder contains three different firebase options files for each environment respectively: `firebase_dev_configuration.dart`, `firebase_stag_configuration.dart` and `firebase_prod_configuration.dart`. The Firebase instance corresponding to the selected environment is used to initialize the app in `main.dart` depending on the chosen app [flavor](https://docs.flutter.dev/deployment/flavors), which are defined in `android/app/build.gradle` to enable different build configurations for Android along different app and package naming so that multiple versions of the app can simultaneously exist on the same device. The configuration files are paired with their respective `google-services.json` files for Android under `android/app/src/development`, `android/app/src/staging` and `android/app/src/production`, which can be downloaded from their respective Firebase projects used to fully separate the environments as recommended [here](https://firebase.google.com/docs/projects/dev-workflows/overview-environments) and [here](https://firebase.google.com/docs/projects/multiprojects).

### Development environment

Used for local development with the [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite). It allows for a perfectly carefree environment where one does not have to worry about BaaS costs while freely adding, reading, querying, modifying or deleting data with or without an internet connection. -- This is the goal anyway, currently works similar to staging with a separate Firebase project and online instance.

To install and run local firebase emulator, follow the below steps:
1. Run `firebase init`
2. Select the desired services:
   -  Firestore: Configure security rules and indexes files for Firestore
   -  Storage: Configure a security rules file for Cloud Storage
   -  Emulators: Set up local emulators for Firebase products
   -  Remote Config: Configure a template file for Remote Config
3. Run `firebase use development` to use the miittiappdev project
4. Say yes to all the default files 
5. Select the emulators to set up:
   - Authentication Emulator
   - Functions Emulator
   - Firestore Emulator
   - Storage Emulator
6. Access the emulators by `CTRL + left mouse click` on the links in the terminal after running `firebase emulators:start`

Run it via `development` configuration in Run and Debug after adding the launch configuration shown below.

Run `flutterfire.bat configure --project=miittiappdev --platforms=android,ios --android-package-name=com.miittisoftwareoy.miitti_app.dev --ios-bundle-id=com.miittisoftwareoy.miittiApp.dev --out=lib/envs/firebase_dev_configuration.dart` to update options or reconfigure and download the associated `google-services.json` to `android/app/src/development` from the Firebase Android app. 

To run via with an emulator, uncomment the related code in `main.dart` and run `firebase use development` before running `firebase emulators:start` and then running `development`. -- DOES NOT WORK CURRENTLY --

### Staging environment

Connects to the MiittiAppDev Firebase project for simulating a real production environment with mock data. Shared between all developers and is thus used for automated and manual testing, hence also requiring a bit more care and courtesy the failure at which is still limited to only increased billing and loss of testing data. All functionality is not available or identical in the local emulator and so their testing and verification here is important. 

Run it via `staging` configuration in Run and Debug after adding the launch configuration shown below.

Run `flutterfire.bat configure --project=miittiappstage --platforms=android,ios --android-package-name=com.miittisoftwareoy.miitti_app.stg --ios-bundle-id=com.miittisoftwareoy.miittiApp.stg --out=lib/envs/firebase_stag_configuration.dart` to update options or reconfigure and download the associated `google-services.json` to `android/app/src/staging` from the Firebase Android app.

### Production environment

Connects to the MiittiApp Firebase project with real user data, where accidents simply cannot happen. 

Run it via `production` configuration in Run and Debug after adding a launch configuration as shown below.

Run `flutterfire.bat configure --project=miitti-app --platforms=android,ios --android-package-name=com.miittisoftwareoy.miitti_app --ios-bundle-id=com.miittisoftwareoy.miittiApp --out=lib/envs/firebase_prod_configuration.dart` to update options or reconfigure and download the associated `google-services.json` to `android/app/src/production` from the Firebase Android app.


To create launch configurations for each environment in VS Code, which can be chosen and run on the Run and Debug page, copy and paste the following into `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "development",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": ["--flavor", "development", "--target", "lib/main.dart" ]
        },
        {
            "name": "staging",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": ["--flavor", "staging", "--target", "lib/main.dart" ]
        },
        {
            "name": "production",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": ["--flavor", "production", "--target", "lib/main.dart" ]
        },
    ],
    "compounds": []
  }
```

Due to lack of MacBooks and iPhones in the development team, flavors nor Firebase projects other than production have not been configured yet for iOS. To edit the environments:
1. Install Firebase CLI using npm (Node.js) in order to access the `firebase` command globally with the command `npm install -g firebase-tools`: https://firebase.google.com/docs/cli#windows-npm and sign in with `firebase login`. This might result in `Error: Cannot run login in non-interactive mode.`, which can be fixed by running `firebase login --interactive` or running the command in a different terminal. 
2. Install FlutterFire CLI by running `dart pub global activate flutterfire_cli`. If the command `flutterfire` is not recognized, add `C:\Users\*username*\AppData\Local\Pub\Cache\bin` to the path variable as shown [here](https://www.youtube.com/watch?v=19HZ19FL1v4) and if it still does not work, try running `flutterfire.bat` instead as mentioned somewhere deep into [this thread](https://stackoverflow.com/questions/70320263/error-the-term-flutterfire-is-not-recognized-as-the-name-of-a-cmdlet-functio).
3. Create project aliases for Firebase projects using [Firebase CLI](https://firebase.google.com/docs/cli) via `firebase use --add`. These are stored in `.firebaserc`. `firebase.json` is mostly responsible for configuring Firebase hosting and is therefore not really relevant for mobile applications.
4. Get SHA1 and SHA-256 keys by running `./gradlew signingReport` and add them to firebase apps for authentication and other services to work.

## Firebase

Firebase is a Backend-as-a-Service (BaaS) solution that we use for authentication, data storage, messaging, analytics and so on.

Reading list:
1. https://firebase.google.com/docs/projects/learn-more
2. https://firebase.google.com/docs/projects/dev-workflows/general-best-practices
3. https://firebase.google.com/support/guides/launch-checklist

## Cloud functions

Initialize by running `firebase init` and selecting Cloud Functions. Overwrite option can be used. 

Make sure your local Node.js is the same as in package.json. Run `npm install` in the `functions` folder to synchronize `package.json` and `package-lock.json`. Deploy a specific cloud function with `firebase deploy --only functions:<functionName>`. Delete a specific function with `firebase functions:delete <functionName>`. 

To run Cloud Functions manually, navigate to console.cloud.google.com and open Cloud Shell. Run any deployed function (even ones that normally require triggers to run) by running the command `gcloud functions call <functionName> --region=<functionRegion>` and supply data to it with the `--data` flag as in the example below: `gcloud functions call generateThumbnail  --data '{"data": {"name": "userImages/6r3QhGLOpuMBsMtaWguPlSEvnNP2/profilePicture.jpg", "contentType": "image/jpeg", "bucket": "gs://miittiappdev.appspot.com"}}' --region=europe-west1`.'

If you get `ERROR: (gcloud.functions.call) You do not currently have an active account selected.`, run `gcloud auth login` and follow the instructions. 

### Authentication

### Remote Config

Remote Config is a relatively self-explanatory way to set `String`, `Number`, `Boolean` and `JSON` values for an app remotely. Where it differs from simply using a regular database such as Firestore for the purpose is that data is meant to flow only in a single direction from the configuration to the app, where it is often cached for much longer and it enables, for example, A/B testing, personalization and fractional rollouts of, for example, new features as well as calling them back. 

The Firebase interaction is encapsulated in `remote_config_service.dart` which uses the defaults loaded from the `.json` files in `lib/constants` until receiving new configurations from Firebase so that remotely configurable values are accessed via the `RemoteConfigService` singleton object, which is initialized in the `remoteConfigService` provider.

https://medium.com/teamkraken/using-firebase-remote-config-in-flutter-dec10d712c68

### Messaging

### Admin SDK

Used for admin sfunctions such as sending messages from a trusted environment such as cloud functions. This is not to be used in the app. 

## State management with Riverpod

Reading list:
1. https://riverpod.dev/docs/introduction/why_riverpod

Providers are initialized upon first access.

Prefer using `ref.watch` over `ref.read`, except for asynchronous methods and State life-cycles such as initState, where `ref.read`should be used instead. https://riverpod.dev/docs/concepts/reading

## Navigation and routing with GoRouter

[GoRouter](https://pub.dev/packages/go_router) is a robust library for navigation and routing, which is defined in `lib/routing/app_router.dart` such that major pages have top-level route whereas UX flows consist of subroutes.

Route `name` and `path` are very different things, where the latter corresponds to URI structure without the [limitations of named routes](https://docs.flutter.dev/ui/navigation), which, on the other hand, simply have non-structural references to them leading to non-customizable deep links and lack of support for browser forward button. 

https://pub.dev/packages/go_router

https://medium.com/@vimehraa29/flutter-go-router-the-crucial-guide-41dc615045bb

https://stackoverflow.com/questions/75233117/how-can-you-change-url-in-the-web-browser-without-named-routes

## Firebase hosting and deep links

Deep links setup guide for Android: https://docs.flutter.dev/cookbook/navigation/set-up-app-links 
Deep links setup guide for iOS: https://docs.flutter.dev/cookbook/navigation/set-up-universal-links

Webflow does not support uploading `assetlinks.json` to `/.well-known/` and therefore the miitti.app domain cannot be used without hosting a reverse proxy (up to 30€ / month). However, a firebase project domain can be used instead.

To do this, set up firebase hosting: https://firebase.google.com/docs/hosting/quickstart and add the `assetlinks.json` and apple variant via `firebase deploy --only hosting`. Be careful, running `firebase deploy` wiped out the entire Remote Config configureation for some reason. Also make sure that `AndroidManifest.xml` contains the correct android:host.

When using DevTools validator, it attempts to access a route of the form `/c:/rest-of-the-link`, which fails claiming that you're trying to access a non flutter project. Change the path to `C:/rest-of-the-link` and it should work: https://github.com/flutter/devtools/issues/7747.

Add headers to `firebase.json` under hosting so that the link is correctly processed and deploy to hosting: 

```
"hosting": {
    "public": "public",
    "headers": [
      {
        "source": "/.well-known/*",
        "headers": [
          {"key": "Content-Type", "value": "application/json"}
        ]
      }
    ],
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
```


## Publishing

Make sure to keep appVersion in `main.dart` up to date!





## Android App Signing for flavors and release

Create a keystore:

```
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks `
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
        -alias upload
```

Access keystore: `keytool -list -v  -keystore C:\Users\Miro\production-keystore.jks` + optionally `-alias production-keystore`

`keytool -list -v  -keystore C:\Users\Miro\miitti-upload-keystore.jks -alias upload`

Clear gradle cache: `./gradlew clean`

Check the used signing fingerprints: `keytool -printcert -jarfile app-production-debug.apk` (must be in miitti_app/build/app/outputs/apk/production/debug or nearby depending on the file)


`upload-key.properties` of the form:

```
keyAlias=alias
keyPassword=password
storeFile=C:\\Users\\User\\miitti-upload-keystore.jks
storePassword=password
```



## Miscellaneous

This can be used to continue from where one left off in the sign up process in combination with LocalStorageService

```

...

if (firstRedirect && userState.isAnonymous && userState.data.gender != null) {
    firstRedirect = false;
    return '/login/complete-profile/gender';
}

if (firstRedirect && userState.isAnonymous && userState.data.birthday != null) {
    firstRedirect = false;
    return '/login/complete-profile/birthday';
}

if (firstRedirect && userState.isAnonymous && userState.data.name != null) {
    firstRedirect = false;
    return '/login/complete-profile/name';
}
```

Android notification icons must use drawables, not mipmaps. Easiest to generate with Android Studio Image Asset Studio: https://developer.android.com/studio/write/create-app-icons#create-notification. They must also be transparent and can only have a single color: https://stackoverflow.com/questions/57362439/notification-icon-doesnt-show-in-flutter-android-app-local-notification-flutter.

## Running on iOS

General instructions: https://docs.flutter.dev/deployment/ios

Make sure to install/update homebrew to the latest version and use it to install cocoabeans. Make sure `Podfile` file has a high enough ios version for your plugins. This might have to be accessed and edited via terminal as I at least could not find it otherwise: for example, `nano Podfile` in `flutter-project/ios`. Finally, disable `ENABLE_USER_SCRIPT_SANDBOX` by settin it to `no`. 

https://stackoverflow.com/questions/78705216/error-running-pod-install-while-running-flutter-app-on-ios-simulator-after-set

https://stackoverflow.com/questions/77561631/please-specify-higher-minimum-deployment-target-dependency

https://github.com/flutter/flutter/issues/32400

https://stackoverflow.com/questions/76590131/error-while-build-ios-app-in-xcode-sandbox-rsync-samba-13105-deny1-file-w

https://stackoverflow.com/questions/71359062/iproxy-cannot-be-opened-because-the-developer-cannot-be-verified

https://ahmedyusuf.medium.com/setup-flavors-in-ios-flutter-with-different-firebase-config-43c4c4823e6b

In root directory:
- `cd ios`
- `rm -rf Pods`
- `rm -rf Podfile.lock`
- `cd ..`
- `flutter clean`
- `flutter upgrade`
- `flutter pub get`
- `cd ios`
- `pod repo update`
- `pod install`
- run

Run with `flutter run --flavor Prod`

Product > clean build folder

Make sure to have the correct `GoogleService-Info.plist` (must be changed for different flavors) and make sure to drop it directly into Xcode (all interaction must be done through Xcode directly)




flutter build ipa