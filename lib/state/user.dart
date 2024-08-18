import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/services/auth_service.dart';

/// A singleton class to manage the current user's authentication state
class UserState extends StateNotifier<User?> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  UserState(this._authService, this._firestoreService, this._localStorageService) : super(null) {
    _authService.authStateChanges.listen((user) {
      state = user;
    });
  }

  User? get user => state;
  String get uid => state?.uid ?? "";
  String get email => state?.email ?? "";
  bool get isSignedIn => state != null;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<bool> signIn(apple) async {
    final result = apple ? await _authService.signInWithApple() : await _authService.signInWithGoogle();
    if (result) {
      state = await _authService.authStateChanges.first;
    }
    return result;
  }

  Future<void> signOut() async {
    state = null;
    final prefs = _localStorageService;
    _firestoreService.reset();
    await _authService.signOut();
    await prefs.clear();
  }

  Future<void> deleteUser() async {
    state = null;
    // TODO: Delete all user's profile picture variants from storage - whole folder corresponding to uid
    final prefs = _localStorageService;
    await _authService.deleteUser();
    await _firestoreService.deleteUser();
    _firestoreService.reset();
    prefs.clear();
  }
}

/// A provider for interacting with the UserState class
final userStateProvider = StateNotifierProvider<UserState, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return UserState(authService, firestoreService, localStorageService);
});

/// A provider that streams the current user's authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final authServiceInstance = ref.watch(userStateProvider.notifier);
  return authServiceInstance.authStateChanges;
});


/// A class to manage the current user's data
class UserData {
  String? uid;
  String? email;
  String? phoneNumber;
  String? name;
  List<String> areas = [];
  Gender? gender;
  List<String> profilePictures = [];
  DateTime? birthday;
  List<Language>? languages;
  String? occupationalStatus;
  String? organization;
  List<String>? favoriteActivities;
  List<String>? invitedActivities;
  Map<String, String> qaAnswers = {};
  Map<String, String>? groups;
  String? fcmToken;
  DateTime? lastActive;
  DateTime? registrationDate;

  UserData({MiittiUser? miittiUser}) {
    if (miittiUser != null) {
      uid = miittiUser.uid;
      email = miittiUser.email;               // TODO: Fetch email from the authentification service - name too maybe? And everything else that is available
      phoneNumber = miittiUser.phoneNumber;
      name = miittiUser.name;
      areas = miittiUser.areas;
      gender = Gender.values.byName(miittiUser.gender);
      profilePictures = miittiUser.profilePictures;
      birthday = miittiUser.birthday.toDate();
      languages = miittiUser.languages.map((language) => Language.values.byName(language)).toList();
      occupationalStatus = miittiUser.occupationalStatus;
      organization = miittiUser.organization;
      favoriteActivities = miittiUser.favoriteActivities;
      invitedActivities = miittiUser.invitedActivities;
      qaAnswers = miittiUser.qaAnswers;
      groups = miittiUser.groups;
      fcmToken = miittiUser.fcmToken;
      lastActive = miittiUser.lastActive.toDate();
      registrationDate = miittiUser.registrationDate.toDate();
    }
  }

  // Getters
  String? get getUid => uid;
  String? get getEmail => email;
  String? get getPhoneNumber => phoneNumber;
  String? get getName => name;
  List<String> get getArea => areas;
  Gender? get getGender => gender;
  List<String> get getProfilePicture => profilePictures;
  DateTime? get getBirthday => birthday;
  List<Language>? get getLanguages => languages;
  String? get getOccupationalStatus => occupationalStatus;
  String? get getOrganization => organization;
  List<String>? get getFavoriteActivities => favoriteActivities;
  List<String>? get getInvitedActivities => invitedActivities;
  Map<String, String>? get getQaAnswers => qaAnswers;
  Map<String, String>? get getGroups => groups;
  String? get getFcmToken => fcmToken;
  DateTime? get getLastActive => lastActive;
  DateTime? get getRegistrationDate => registrationDate;

  // Setters
  void setUid(String? value) => uid = value;
  void setEmail(String? value) => email = value;
  void setPhoneNumber(String? value) => phoneNumber = value;
  void setName(String? value) => name = value;
  void setAreas(List<String> value) => areas = value;
  void setGender(Gender? value) => gender = value;
  void setProfilePicture(List<String> value) => profilePictures = value;
  void setBirthday(DateTime? value) => birthday = value;
  void setLanguages(List<Language>? value) => languages = value;
  void setOccupationalStatus(String? value) => occupationalStatus = value;
  void setOrganization(String? value) => organization = value;
  void setFavoriteActivities(List<String>? value) => favoriteActivities = value;
  void setInvitedActivities(List<String>? value) => invitedActivities = value;
  void setQaAnswers(Map<String, String> value) => qaAnswers = value;
  void setGroups(Map<String, String>? value) => groups = value;
  void setFcmToken(String? value) => fcmToken = value;
  void setLastActive(DateTime? value) => lastActive = value;
  void setRegistrationDate(DateTime? value) => registrationDate = value;

  // TODO: Implement a method to update the user's data in Firestore

  // TODO: Implement a method to clear the class' data upon sign out / user deletion
}

final userDataProvider = Provider<UserData>((ref) {
  final user = ref.watch(firestoreServiceProvider).miittiUser;
  return UserData(miittiUser: user);
});