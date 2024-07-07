# Notes

Notes, remarks, tips & tricks, links to useful resources and other miscellaneous documentation on broader topics, technologes and development in general. The idea is for this to be a great place for new developers to quickly browse through and occasionally return to in order to quickly get up to speed on a new area of development. 

## Code Guidelines

To facilitate seamless collaboration, a set of guidelines for writing code, organizing the project and using git has been established and written at: https://docs.google.com/document/d/1Mg8uGGTysDH5yLrEbZZMRYrex6_8VIaa9aV8Bjrf88E/edit?usp=sharing.

## Flutter

Perhaps the best resource for learning Flutter is its documentation: https://docs.flutter.dev/

Reading list:
1. https://flutter.dev/
2. https://flutter.dev/learn
3. https://dart.dev/language
4. https://dart.dev/effective-dart
5. https://dart.dev/language/async

## Firebase

Reading list:
1. https://firebase.google.com/docs/projects/learn-more
2. https://firebase.google.com/docs/projects/dev-workflows/general-best-practices
3. https://firebase.google.com/support/guides/launch-checklist

### Authentication

## Development, staging and production environments

The broad idea of different environments is to have the same code interact with different data depending on where it is currently in the development cycle. The development version can interact with mock data separated from the real database, whereas the production version operates with real user data. This separation allows for freely testing different kinds of data without having to worry about accidents or pollution of the real database. Furthermore, it can be cheaper to not have to call the real database and less confusing for our users when we do not have to worry about accidentally displaying mock data in our app. 

The three development, staging and production environments are currently configured according to [this article](https://medium.com/flutter-community/using-different-environments-with-firebase-and-flutter-aa4fb0e0dd52) so that the `envs` folder contains three different firebase options files for each environment respectively: `firebase_dev_configuration.dart`, `firebase_stag_configuration.dart` and `firebase_prod_configuration.dart`. The Firebase instance corresponding to the selected environment is used to initialize the app in `main.dart` depending on the chosen app [flavor](https://docs.flutter.dev/deployment/flavors), which are defined in `android/app/build.gradle` to enable different build configurations for Android along different app and package naming so that multiple versions of the app can simultaneously exist on the same device. The configuration files are paired with their respective `google-services.json` files for Android under `android/app/src/development`, `android/app/src/staging` and `android/app/src/production`, which can be downloaded from their respective Firebase projects used to fully separate the environments as recommended [here](https://firebase.google.com/docs/projects/dev-workflows/overview-environments) and [here](https://firebase.google.com/docs/projects/multiprojects).






On windows, these are configured with the below commands respectively:

1st command

`flutterfire.bat configure --project=miittiappdev --platforms=android,ios --android-package-name=com.miittisoftwareoy.miitti_app.stg --ios-bundle-id=com.miittisoftwareoy.miittiApp.stg --out=lib/envs/firebase_stag_configuration.dart`

`flutterfire.bat configure --project=miittiapp-8182e --platforms=android,ios --android-package-name=com.miittisoftwareoy.miitti_app --ios-bundle-id=com.miittisoftwareoy.miittiApp --out=lib/envs/firebase_prod_configuration.dart`




### Development environment

Used for local development with the [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite). It allows for a perfectly carefree environment where one does not have to worry about BaaS costs while freely adding, reading, querying, modifying or deleting data with or without an internet connection. 

### Staging environment

Connects to the MiittiAppDev Firebase project for simulating a real production environment with mock data. Shared between all developers and is thus used for automated and manual testing, hence also requiring a bit more care and courtesy the failure at which is still limited to only increased billing and loss of testing data. All functionality is not available or identical in the local emulator and so their testing and verification here is important.

### Production environment

Connects to the MiittiApp Firebase project with real user data, where accidents simply cannot happen. 

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









- Use Local Firebase Emulator: https://www.youtube.com/watch?v=pkgvFNPdiEs
- Set it up: https://medium.com/@edawarekaro/mastering-firebase-emulator-suite-with-flutter-a-comprehensive-guide-for-beginners-dceb74cbac8b


Separate firebase projects for development and production do not increase costs as billing is project-based, not account-based: 
- https://stackoverflow.com/questions/70233194/are-firebase-and-google-cloud-free-usage-quotas-tied-to-different-things-projec?noredirect=1&lq=1
- https://stackoverflow.com/questions/58440882/google-cloud-tiered-billing-project-v-billing-account

- Flutter flavors are one method to create different compile-time configurations for an app, which can be used both for configuring different environments as well as, for example, differentiating between free and paid versions by offering different features. Another major bonus is the ability to have two versions of the app on your phone simultaneously as a development preview and the actual currently published app with different names and icons: https://docs.flutter.dev/deployment/flavors








## State management

Reading list:
1. https://riverpod.dev/docs/introduction/why_riverpod

## Navigation and routing

https://pub.dev/packages/go_router

https://medium.com/@vimehraa29/flutter-go-router-the-crucial-guide-41dc615045bb

https://stackoverflow.com/questions/75233117/how-can-you-change-url-in-the-web-browser-without-named-routes