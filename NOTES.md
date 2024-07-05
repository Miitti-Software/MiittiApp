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

## Development and production environments

The broad idea of different environments is to have exactly the same code interact with different data depending on where it is currently in the development cycle. For example, the development version can be named "Miitti Dev" and have a different icon highlighting that while operating with mock data separated from the real database, whereas the production version interacts with real user data. This separation allows for freely testing different kinds of data without having to worry about accidents or pollution of the real database. Furthermore, it can be cheaper to not have to call the real database and it enables freely testing without confusing our users with, for example, Miittis that do not really exist. Another added bonus is the ability to have two versions of the app on your phone simultaneously as a development preview and the actual currently published app.

- Flutter flavors are one method to create different compile-time configurations for an app, which can be used both for configuring different environments as well as, for example, differentiating between free and paid versions by offering different features: https://docs.flutter.dev/deployment/flavors
    - https://medium.com/@animeshjain/build-flavors-in-flutter-android-and-ios-with-different-firebase-projects-per-flavor-27c5c5dac10b

https://firebase.google.com/docs/projects/dev-workflows/overview-environments

https://firebase.google.com/docs/projects/multiprojects



Setting up and understanding working with environments in Flutter and Firebase: https://medium.com/flutter-community/using-different-environments-with-firebase-and-flutter-aa4fb0e0dd52

## State management

Reading list:
1. https://riverpod.dev/docs/introduction/why_riverpod

## Navigation and routing

https://pub.dev/packages/go_router

https://medium.com/@vimehraa29/flutter-go-router-the-crucial-guide-41dc615045bb

https://stackoverflow.com/questions/75233117/how-can-you-change-url-in-the-web-browser-without-named-routes