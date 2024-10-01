import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';

class UserState extends StateNotifier<UserStateData> {
  UserState(this.ref) : super(UserStateData()) {
    initializeState();
  }

  final Ref ref;
  final Location _liveLocation = Location();
  Timer? _locationUpdateTimer;

  Future<void> initializeState() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final miittiUser = await _loadMiittiUser(user.uid);
      final latestLocation = await _getLocationFromStorage();
      state = UserStateData(
        user: user,
        data: miittiUser != null 
          ? UserData.fromMiittiUser(miittiUser, latestLocation: latestLocation) 
          : UserData(uid: user.uid, name: state.data.name, email: state.data.email),
      );
    }
    authService.authStateChanges.listen(_handleAuthStateChanges);
    _startLiveLocationUpdates();
  }

  Future<MiittiUser?> _loadMiittiUser(String uid) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    return await firestoreService.loadUserData(uid);
  }

  Future<void> _handleAuthStateChanges(User? user) async {
    if (user != null) {
      final miittiUser = await _loadMiittiUser(user.uid);
      final latestLocation = await _getLocationFromStorage();
      state = UserStateData(
        user: user,
        data: miittiUser != null 
          ? UserData.fromMiittiUser(miittiUser, latestLocation: latestLocation) 
          : UserData(uid: user.uid, name: state.data.name, email: state.data.email),
      );
    } else {
      state = UserStateData();
    }
  }

  Future<bool> signIn(bool apple) async {
    final authService = ref.read(authServiceProvider);
    final result = apple ? await authService.signInWithApple() : await authService.signInWithGoogle();
    if (result) {
      final user = await authService.authStateChanges.first;
      if (user != null) {
        final miittiUser = await _loadMiittiUser(user.uid);
        final latestLocation = await _getLocationFromStorage();
        state = UserStateData(
          user: user,
          data: miittiUser != null 
            ? UserData.fromMiittiUser(miittiUser, latestLocation: latestLocation) 
            : UserData(uid: user.uid, name: state.data.name, email: state.data.email),
        );
        if (!state.isAnonymous) {
          ref.read(notificationServiceProvider).initialize();
        }
      }
    }
    return result;
  }

  Future<void> createUser() async {
    if (state.isSignedIn) {
      final firestoreService = ref.read(firestoreServiceProvider);
      MiittiUser miittiUser = MiittiUser(
        uid: state.uid!,
        email: state.email?.trim() ?? '',
        name: state.data.name!.trim(),
        gender: state.data.gender!,
        birthday: state.data.birthday!,
        languages: state.data.languages,
        occupationalStatuses: state.data.occupationalStatuses,
        organizations: state.data.organizations,
        representedOrganizations: [],
        areas: state.data.areas,
        favoriteActivities: state.data.favoriteActivities,
        qaAnswers: state.data.qaAnswers,
        profilePicture: state.data.profilePicture!,
        registrationDate: DateTime.now(),
        lastActive: DateTime.now(),
        fcmToken: '',
        online: true,

        numOfActivitiesCreated: 0,
        numOfActivitiesJoined: 0,
        numOfActivitiesAttended: 0,
        peopleMet: [],
        activitiesTried: [],

        languageSetting: ref.read(languageProvider),
      );
      final imageUrl = await ref.read(firebaseStorageServiceProvider).uploadProfilePicture(state.uid!, File(state.data.profilePicture!));
      miittiUser.profilePicture = imageUrl;
      await firestoreService.saveUserData(miittiUser);
      state = state.copyWith(data: UserData.fromMiittiUser(miittiUser));
    }
  }

  Future<void> updateUserData() async {
    if (state.isSignedIn && !state.isAnonymous) {
      final firestoreService = ref.read(firestoreServiceProvider);
      MiittiUser miittiUser = state.data.toMiittiUser();
      await firestoreService.saveUserData(miittiUser);
    }
  }

  Future<void> sessionUpdateUserData({bool begin = false}) async {
    if (state.isSignedIn && !state.isAnonymous && state.data.profilePicture != null && state.data.profilePicture!.startsWith('http')) {
      final firestoreService = ref.read(firestoreServiceProvider);
      MiittiUser miittiUser = state.data.copyWith(
        lastActive: DateTime.now(),
        online: begin,
      ).toMiittiUser();
      await firestoreService.updateUserData(miittiUser);
    }
  }

  Future<void> updateUserProfilePicture(String imagePath) async {
    if (state.isSignedIn && !state.isAnonymous) {
      final imageUrl = await ref.read(firebaseStorageServiceProvider).uploadProfilePicture(state.uid!, File(imagePath));
      state = state.copyWith(data: state.data.setProfilePicture(imageUrl));
      await updateUserData();
    }
  }

  Future<bool> updateLocation() async {
    final locationPermissionNotifier = ref.read(locationPermissionProvider.notifier);
    if (state.isSignedIn && locationPermissionNotifier.state) {
      try {
        LocationData locationData = await _liveLocation.getLocation();
        if (locationData.latitude != null && locationData.longitude != null) {
          final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
          state = state.copyWith(
            data: state.data.copyWith(latestLocation: newLocation),
          );
          _saveLocationToStorage(newLocation);
          return true;
        }
      } catch (e) {
        debugPrint('Error updating location: $e');
      }
    }
    return false;
  }

  int getAge() {
    if (state.data.birthday != null) {
      final now = DateTime.now();
      final age = now.year - state.data.birthday!.year;
      final month1 = now.month;
      final month2 = state.data.birthday!.month;
      if (month2 > month1 || (month1 == month2 && now.day < state.data.birthday!.day)) {
        return age - 1;
      }
      return age;
    }
    return 0;
  }

  Future<LatLng?> _getLocationFromStorage() async {
    final localStorageService = ref.read(localStorageServiceProvider);
    if (state.isSignedIn) {
      double? latitude = await localStorageService.getDouble('latestLatitude');
      double? longitude = await localStorageService.getDouble('latestLongitude');
      if (latitude != null && longitude != null) {
        return LatLng(latitude, longitude);
      }
    }
    return null;
  }

  void _saveLocationToStorage(LatLng location) {
    final localStorageService = ref.read(localStorageServiceProvider);
    localStorageService.saveDouble('latestLatitude', location.latitude);
    localStorageService.saveDouble('latestLongitude', location.longitude);
  }

  void _startLiveLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      updateLocation();
    });
  }

  setLanguageSetting(Language language) {
    ref.read(languageProvider.notifier).setLanguage(language);
    state = state.copyWith(data: state.data.copyWith(languageSetting: language));
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> updateLastActive() async {
    if (state.isSignedIn) {
      state = state.copyWith(
        data: state.data.copyWith(lastActive: DateTime.now()),
      );
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final localStorageService = ref.read(localStorageServiceProvider);

    await authService.signOut();
    firestoreService.reset();
    await localStorageService.clear();
    _locationUpdateTimer?.cancel();
    state = UserStateData();
  }

  Future<void> deleteUser() async {
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final firebaseStorageService = ref.read(firebaseStorageServiceProvider);
    final localStorageService = ref.read(localStorageServiceProvider);

    if (!state.isAnonymous) {
      await firebaseStorageService.deleteUserFolder(state.uid!);
      await firestoreService.deleteUser(state.uid!);
    }
    await authService.deleteUser();
    await localStorageService.clear();
    firestoreService.reset();
    _locationUpdateTimer?.cancel();
    state = UserStateData();
  }

  void update(Function(UserStateData) updateFn) {
    state = updateFn(state);
  }

  incrementActivitiesJoined() {
    state = state.copyWith(data: state.data.incrementActivitiesJoined());
  }

  decrementActivitiesJoined() {
    state = state.copyWith(data: state.data.decrementActivitiesJoined());
  }

  incrementActivitiesCreated() {
    state = state.copyWith(data: state.data.incrementActivitiesCreated());
  }

  Future<void> refreshUserData() async {
    if (state.isSignedIn) {
      final miittiUser = await _loadMiittiUser(state.uid!);
      if (miittiUser != null) {
        state = state.copyWith(
          data: UserData.fromMiittiUser(miittiUser, latestLocation: state.data.latestLocation),
        );
      }
    }
  }
}

class UserStateData {
  final User? user;
  final UserData data;

  UserStateData({
    this.user,
    UserData? data,
  }) : data = data ?? UserData();

  bool get isSignedIn => user != null;
  String? get uid => user?.uid;
  String? get email => user?.email;
  bool get isAnonymous => data.registrationDate == null;

  UserStateData copyWith({
    User? user,
    UserData? data,
  }) {
    return UserStateData(
      user: user ?? this.user,
      data: data ?? this.data,
    );
  }
}

class UserData {
  final String? uid;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final Gender? gender;
  final DateTime? birthday;
  final List<Language> languages;
  final List<String> occupationalStatuses;
  final List<String> organizations;
  final List<String> representedOrganizations;
  final List<String> areas;
  final List<String> favoriteActivities;
  final Map<String, String> qaAnswers;
  final String? profilePicture;
  final DateTime? registrationDate;
  final LatLng? latestLocation;
  final DateTime? lastActive;
  final String? fcmToken;
  final bool online;

  final int numOfActivitiesCreated;
  final int numOfActivitiesJoined;
  final int numOfActivitiesAttended;
  final List<String> peopleMet;
  final List<String> activitiesTried;

  final Language languageSetting;

  UserData({
    this.uid,
    this.email,
    this.phoneNumber,
    this.name,
    this.gender,
    this.birthday,
    this.languages = const [],
    this.occupationalStatuses = const [],
    this.organizations = const [],
    this.representedOrganizations = const [],
    this.areas = const [],
    this.favoriteActivities = const [],
    this.qaAnswers = const {},
    this.profilePicture,
    this.registrationDate,
    this.latestLocation,
    this.lastActive,
    this.fcmToken,
    this.online = true,

    this.numOfActivitiesCreated = 0,
    this.numOfActivitiesJoined = 0,
    this.numOfActivitiesAttended = 0,
    this.peopleMet = const [],
    this.activitiesTried = const [],

    this.languageSetting = Language.en,
  });

  factory UserData.fromMiittiUser(MiittiUser miittiUser, {LatLng? latestLocation}) {
    return UserData(
      uid: miittiUser.uid,
      email: miittiUser.email,
      phoneNumber: miittiUser.phoneNumber,
      name: miittiUser.name,
      gender: miittiUser.gender,
      birthday: miittiUser.birthday,
      languages: miittiUser.languages,
      occupationalStatuses: miittiUser.occupationalStatuses,
      organizations: miittiUser.organizations,
      representedOrganizations: miittiUser.representedOrganizations,
      areas: miittiUser.areas,
      favoriteActivities: miittiUser.favoriteActivities,
      qaAnswers: miittiUser.qaAnswers,
      profilePicture: miittiUser.profilePicture,
      registrationDate: miittiUser.registrationDate,
      latestLocation: latestLocation,
      lastActive: miittiUser.lastActive,
      fcmToken: miittiUser.fcmToken,
      online: true,

      numOfActivitiesCreated: miittiUser.numOfActivitiesCreated,
      numOfActivitiesJoined: miittiUser.numOfActivitiesJoined,
      numOfActivitiesAttended: miittiUser.numOfActivitiesAttended,
      peopleMet: miittiUser.peopleMet,
      activitiesTried: miittiUser.activitiesTried,

      languageSetting: miittiUser.languageSetting,
    );
  }

  UserData copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? name,
    Gender? gender,
    DateTime? birthday,
    List<Language>? languages,
    List<String>? occupationalStatuses,
    List<String>? organizations,
    List<String>? representedOrganizations,
    List<String>? areas,
    List<String>? favoriteActivities,
    Map<String, String>? qaAnswers,
    String? profilePicture,
    DateTime? registrationDate,
    LatLng? latestLocation,
    DateTime? lastActive,
    String? fcmToken,
    bool? online,

    int? numOfActivitiesCreated,
    int? numOfActivitiesJoined,
    int? numOfActivitiesAttended,
    List<String>? peopleMet,
    List<String>? activitiesTried,

    Language? languageSetting,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      languages: languages ?? this.languages,
      occupationalStatuses: occupationalStatuses ?? this.occupationalStatuses,
      organizations: organizations ?? this.organizations,
      representedOrganizations: representedOrganizations ?? this.representedOrganizations,
      areas: areas ?? this.areas,
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      qaAnswers: qaAnswers ?? this.qaAnswers,
      profilePicture: profilePicture ?? this.profilePicture,
      registrationDate: registrationDate ?? this.registrationDate,
      latestLocation: latestLocation ?? this.latestLocation,
      lastActive: DateTime.now(),
      fcmToken: fcmToken ?? this.fcmToken,
      online: online ?? this.online,

      numOfActivitiesCreated: numOfActivitiesCreated ?? this.numOfActivitiesCreated,
      numOfActivitiesJoined: numOfActivitiesJoined ?? this.numOfActivitiesJoined,
      numOfActivitiesAttended: numOfActivitiesAttended ?? this.numOfActivitiesAttended,
      peopleMet: peopleMet ?? this.peopleMet,
      activitiesTried: activitiesTried ?? this.activitiesTried,

      languageSetting: languageSetting ?? this.languageSetting,
    );
  }

  MiittiUser toMiittiUser() {
    return MiittiUser(
      uid: uid!,
      email: email!.trim(),
      name: name!.trim(),
      gender: gender!,
      birthday: birthday!,
      languages: languages,
      occupationalStatuses: occupationalStatuses,
      organizations: organizations,
      representedOrganizations: representedOrganizations,
      areas: areas,
      favoriteActivities: favoriteActivities,
      qaAnswers: qaAnswers,
      profilePicture: profilePicture!,
      registrationDate: registrationDate!,
      lastActive: lastActive!,
      fcmToken: fcmToken!,
      online: online,

      numOfActivitiesCreated: numOfActivitiesCreated,
      numOfActivitiesJoined: numOfActivitiesJoined,
      numOfActivitiesAttended: numOfActivitiesAttended,
      peopleMet: peopleMet,
      activitiesTried: activitiesTried,

      languageSetting: languageSetting,
    );
  }

  setBirthday(DateTime birthday) {
    return copyWith(birthday: birthday);
  }

  setEmail(String email) {
    return copyWith(email: email);
  }

  setGender(Gender gender) {
    return copyWith(gender: gender);
  }

  setName(String name) {
    return copyWith(name: name);
  }

  setProfilePicture(String profilePicture) {
    return copyWith(profilePicture: profilePicture);
  }

  addLanguage(Language language) {
    return copyWith(languages: [...languages, language]);
  }

  removeLanguage(Language language) {
    return copyWith(languages: languages.where((l) => l != language).toList());
  }

  addArea(String area) {
    return copyWith(areas: [...areas, area]);
  }

  removeArea(String area) {
    return copyWith(areas: areas.where((a) => a != area).toList());
  }

  addOccupationalStatus(String occupationalStatus) {
    return copyWith(occupationalStatuses: [...occupationalStatuses, occupationalStatus]);
  }

  removeOccupationalStatus(String occupationalStatus) {
    return copyWith(occupationalStatuses: occupationalStatuses.where((o) => o != occupationalStatus).toList());
  }

  addOrganization(String organization) {
    return copyWith(organizations: [...organizations, organization]);
  }

  removeOrganization(String organization) {
    return copyWith(organizations: organizations.where((o) => o != organization).toList());
  }

  addFavoriteActivity(String activity) {
    return copyWith(favoriteActivities: [...favoriteActivities, activity]);
  }

  removeFavoriteActivity(String activity) {
    return copyWith(favoriteActivities: favoriteActivities.where((a) => a != activity).toList());
  }

  addQaAnswer(String question, String answer) {
    final updatedQaAnswers = Map<String, String>.from(qaAnswers);
    updatedQaAnswers[question] = answer;
    return copyWith(qaAnswers: updatedQaAnswers);
  }

  removeQaAnswer(String question) {
    final updatedQaAnswers = Map<String, String>.from(qaAnswers);
    updatedQaAnswers.remove(question);
    return copyWith(qaAnswers: updatedQaAnswers);
  }

  setFcmToken(String fcmToken) {
    return copyWith(fcmToken: fcmToken);
  }

  incrementActivitiesJoined() {
    return copyWith(numOfActivitiesJoined: numOfActivitiesJoined + 1);
  }

  decrementActivitiesJoined() {
    return copyWith(numOfActivitiesJoined: numOfActivitiesJoined - 1);
  }

  incrementActivitiesCreated() {
    return copyWith(numOfActivitiesCreated: numOfActivitiesCreated + 1);
  }

}

final userStateProvider = StateNotifierProvider<UserState, UserStateData>((ref) {
  return UserState(ref);
});

final signedInProvider = Provider<bool>((ref) {
  return ref.watch(userStateProvider).isSignedIn;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});