import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

/// A class that represents the condition used to geographically query activities based on the visible area on the map.
class GeoQueryCondition {
  GeoQueryCondition({
    required this.radiusInKm,
    required this.center,
  });

  final double radiusInKm;
  final LatLng center;
}

/// A StateNotifier class that manages the loading and updating of activities.
class ActivitiesState extends StateNotifier<ActivitiesStateData> {
  ActivitiesState(this.ref) : super(ActivitiesStateData()) {
    _geoQueryCondition.stream.listen(_updateActivities);
    _initializeFirestoreListener();
  }

  final Ref ref;                                                          // A reference to the ProviderContainer, which allows global access to Riverpod providers.
  Timer? _debounce;                                                       // A timer used to debounce the update of activities in order to save reads bandwidth.
  final _geoQueryCondition = BehaviorSubject<GeoQueryCondition>.seeded(   // A BehaviorSubject that emits the current GeoQueryCondition used to fetch activities based on the visible area on the map. Initialized with the coordinates of Helsinki.
    GeoQueryCondition(
      radiusInKm: 1.0,
      center: const LatLng(60.1699, 24.9325),
    ),
  );
  bool _isLoadingMore = false;                                            // A boolean that indicates whether the app is currently loading more activities.

  // Initialize the Firestore listener that listens for live updates on activities.
  void _initializeFirestoreListener() {
    if (ref.read(userStateProvider).isAnonymous) return;
    final firestoreService = ref.read(firestoreServiceProvider);
    firestoreService.streamUserCreatedActivities().listen((updatedActivities) {
      _updateRequestsAndParticipants(updatedActivities);
    });
  }

  // Calculates the largest radius of the visible area on the map based on the zoom level taking into account the curvature of the Earth.
  double _calculateRadius(
    double zoom, {
    double mapLongSidePixels = 250,
    double ratio = 100,
    double degree = 45,
  }) {
    double km;
    zoom = zoom;
    var k = mapLongSidePixels * 156543.03392 * cos(degree * pi / 180);
    km = ratio * k / (pow(e, ln2 * zoom) * 100);
    km = km / 1000;
    return km;
  }

  // Updates the lists of activities in the state of the StateNotifier 
  void _updateState() {
    final userState = ref.read(userStateProvider);
    if (!userState.isAnonymous) {
      final userId = ref.read(userStateProvider).uid!;
      final List<MiittiActivity> userActivities = [];
      final List<MiittiActivity> othersActivities = [];
      final List<MiittiActivity> visibleActivities = [];
      final List<MiittiActivity> requestedActivities = [];
      final List<MiittiActivity> participatingActivities = [];

      for (var activity in state.activities) {
        if (activity.participants.contains(userId)) {
          participatingActivities.add(activity);
        } else if (activity is UserCreatedActivity && activity.requests.contains(userId)) {
          requestedActivities.add(activity);
        } 
        if (activity.creator == userId) {
          userActivities.add(activity);
        } else if (activity.participants.contains(userId) || (activity is UserCreatedActivity && activity.requests.contains(userId))) {
          othersActivities.add(activity);
        }
        if (activity.endTime == null || activity.endTime!.isAfter(DateTime.now())) {
          visibleActivities.add(activity);
        }
      }

      state = state.copyWith(
        userActivities: userActivities,
        othersActivities: othersActivities,
        visibleActivities: visibleActivities,
        participatingActivities: participatingActivities,
      );
    }
  }

  // Updates the activities in the state based on the GeoQueryCondition.
  void _updateActivities(GeoQueryCondition geoQueryCondition) {
    final firestoreService = ref.read(firestoreServiceProvider);

    firestoreService.streamActivitiesWithinRadius(
      geoQueryCondition.center,
      geoQueryCondition.radiusInKm,
    ).listen((newActivities) {
      final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
      final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

      if (filteredActivities.isNotEmpty) {
        state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
        _updateState();
      }
    });
  }

  // Updates the requests and participants of the UserCreatedActivities in the state based on the updated activities.
  void _updateRequestsAndParticipants(List<UserCreatedActivity> updatedActivities) {
    debugPrint('Updating requests and participants');
    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final updatedStateActivities = state.activities.map((activity) {
      if (activity is UserCreatedActivity) {
        final updatedActivity = updatedActivities.firstWhere((a) => a.id == activity.id, orElse: () => activity);
        return updatedActivity;
      }
      return activity;
    }).toList();

    final newActivitiesToAdd = updatedActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (newActivitiesToAdd.isNotEmpty || updatedStateActivities.isNotEmpty) {
      state = state.copyWith(activities: updatedStateActivities.followedBy(newActivitiesToAdd).toList());
      _updateState();
    }
  }

  /// Updates the GeoQueryCondition based on the center point and zoom of the map.
  void updateGeoQueryCondition(LatLng center, double zoom) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final radiusInKm = _calculateRadius(zoom, degree: center.latitude);
      _geoQueryCondition.add(GeoQueryCondition(center: center, radiusInKm: radiusInKm));
    });
  }

  /// Returns the activity whose ID was provided. If it is contained in the state, no additional reads are made.
  /// If it is not, the activity is fetched from Firestore and added to the state of the ActivitiesState StateNotifier.
  Future<MiittiActivity?> fetchActivity(String activityId) async {
    if (state.activities.any((element) => element.id == activityId)) {
      return state.activities.firstWhere((element) => element.id == activityId);
    }
    final firestoreService = ref.read(firestoreServiceProvider);
    MiittiActivity? activity = await firestoreService.fetchActivity(activityId);
    if (activity == null) {
      debugPrint('Activity with ID $activityId does not exist.');
      return null;
    }
    state = state.copyWith(activities: state.activities.followedBy([activity]).toList());
    return activity;
  }

  /// Loads more activities from Firestore based on the current GeoQueryCondition.
  /// If fullRefresh is true, the state is emptied and activities are fully refetched.
  /// If onlyParticipating is true, only activities where the current user is a participant are fetched.
  Future<void> loadMoreActivities({bool fullRefresh = false, bool onlyParticipating = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    if (fullRefresh) {
      state = state.copyWith(activities: []);
      _updateState();
    }

    final firestoreService = ref.read(firestoreServiceProvider);

    List<MiittiActivity> newActivities = 
      onlyParticipating ? await firestoreService.fetchParticipatingActivities(pageSize: 10, fullRefresh: fullRefresh) : await firestoreService.fetchFilteredActivities(pageSize: 10, fullRefresh: fullRefresh);

    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (filteredActivities.isNotEmpty) {
      state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
    }

    _isLoadingMore = false;
    _updateState();
  }

  /// Marks an activity as seen at a given moment by the current user.
  void markSeenLocally(MiittiActivity activity) {
    final seenActivity = Tuple2(activity, DateTime.now());
    if (!state.seenActivities.any((tuple) => tuple.item1.id == activity.id)) {
      state = state.copyWith(seenActivities: [...state.seenActivities, seenActivity]);
    }
  }

  /// Updates the activities as seen by the current user in Firestore.
  Future<bool> sessionUpdateActivitiesData() async {
    try {
      final userState = ref.read(userStateProvider);
      final userId = userState.uid;
      if (userId == null) return false;

      final firestoreService = ref.read(firestoreServiceProvider);

      // Filter activities that are marked as seen and the user is a participant
      final seenActivities = state.activities.where((activity) {
        return state.seenActivities.any((tuple) => tuple.item1.id == activity.id) && activity.participants.contains(userId);
      }).toList();

      // Update each seen activity in Firebase
      for (var activity in seenActivities) {
        await firestoreService.updateActivity(activity.markSeen(userId).toMap(), activity.id, activity is CommercialActivity);
      }

      // Clear the seen activities list
      state = state.copyWith(seenActivities: []);

      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error updating activities data: $e');
      return false;
    }
  }

  /// Deletes an activity from Firestore and removes it from the state of the ActivitiesState StateNotifier.
  Future<bool> deleteActivity(MiittiActivity activity) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteActivity(activity.id);
      state = state.copyWith(activities: state.activities.where((a) => a.id != activity.id).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }

  /// Remove the current user from the participants list of the given activity.
  Future<bool> leaveActivity(MiittiActivity activity) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      activity.removeParticipant(ref.read(userStateProvider).data.toMiittiUser());
      await firestoreService.updateActivity(activity.toMap(), activity.id, activity is CommercialActivity);
      ref.read(userStateProvider.notifier).decrementActivitiesJoined();
      state = state.copyWith(activities: state.activities.map((a) => a.id == activity.id ? activity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error leaving activity: $e');
      return false;
    }
  }

  /// Removes a given participant from the given activity.
  Future<bool> removeParticipant(UserCreatedActivity activity, MiittiUser user) async {
    try {
      if (user.uid == activity.creator) return false;
      final firestoreService = ref.read(firestoreServiceProvider);
      final updatedActivity = activity.removeParticipant(user);
      await firestoreService.updateActivity(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  /// Adds the current user to the participants list of the given activity and sends a notification to the creator of the activity.
  Future<bool> joinActivity(MiittiActivity activity) async {
    try {
      final userState = ref.read(userStateProvider);
      if (userState.isAnonymous || activity.participants.contains(userState.uid)) {
        return false;
      }
      final firestoreService = ref.read(firestoreServiceProvider);
      MiittiActivity updatedActivity = activity.addParticipant(ref.read(userStateProvider).data.toMiittiUser());
      final success = await firestoreService.updateActivity(updatedActivity.notifyParticipants().markSeen(userState.uid!).toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      if (updatedActivity is UserCreatedActivity) {
        ref.read(notificationServiceProvider).sendJoinNotification(updatedActivity);
        ref.read(analyticsServiceProvider).logActivityJoined(updatedActivity, ref.read(userStateProvider).data.toMiittiUser());
      } else {
        ref.read(analyticsServiceProvider).logCommercialActivityJoined(updatedActivity as CommercialActivity, ref.read(userStateProvider).data.toMiittiUser());
      }
      ref.read(userStateProvider.notifier).incrementActivitiesJoined();
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error joining activity: $e');
      return false;
    }
  }

  /// Requests to join the given activity and sends a notification to the creator of the activity.
  Future<bool> requestToJoinActivity(UserCreatedActivity activity) async {
    try {
      final userState = ref.read(userStateProvider);
      if (userState.isAnonymous || activity.requests.contains(userState.uid) || activity.participants.contains(userState.uid)) {
        return false;
      }
      final firestoreService = ref.read(firestoreServiceProvider);
      UserCreatedActivity updatedActivity = activity.addRequest(ref.read(userStateProvider).uid!);
      final success = await firestoreService.updateActivity(updatedActivity.notifyParticipants().markSeen(userState.uid!).toMap(), updatedActivity.id, activity is CommercialActivity);
      if (!success) return false;
      ref.read(userStateProvider.notifier).incrementActivitiesJoined();
      ref.read(analyticsServiceProvider).logActivityJoined(updatedActivity, ref.read(userStateProvider).data.toMiittiUser());
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error requesting to join activity: $e');
      return false;
    }
  }

  /// Accepts the request of the given user to join the given activity by moving them from requests to participants and sending them a notification.
  Future<bool> acceptRequest(String activityId, MiittiUser user) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final activity = state.activities.firstWhere((a) => a.id == activityId) as UserCreatedActivity;
      final updatedActivity = activity.removeRequest(user.uid).addParticipant(user);
      final success = await firestoreService.updateActivity(updatedActivity.notifyParticipants().markSeen(ref.read(userStateProvider).uid!).toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      ref.read(notificationServiceProvider).sendRequestAcceptedNotification(updatedActivity);
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  /// Declines the request of the given user to join the given activity by removing them from requests.
  Future<bool> declineRequest(String activityId, String userId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final activity = state.activities.firstWhere((a) => a.id == activityId) as UserCreatedActivity;
      final updatedActivity = activity.removeRequest(userId);
      final success = await firestoreService.updateActivity(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error declining request: $e');
      return false;
    }
  }

  /// Returns whether any of the activities the current user is partakin in have newer updates than since they were last seen.
  bool hasNewActivityUpdates(String userId) {
    return state.activities.any((activity) {
      final isParticipant = activity.participants.contains(userId);
      final lastSeen = activity.participantsInfo[userId]?['lastSeen'];
      final condition = state.seenActivities.any((tuple) => tuple.item1.id == activity.id && tuple.item2.isAfter(activity.latestActivity));
      return isParticipant && (lastSeen == null && !condition || lastSeen != null && (activity.latestActivity.isAfter(lastSeen)) && !condition);
    });
  }

  @override
  void dispose() {
    _geoQueryCondition.close();
    _debounce?.cancel();
    super.dispose();
  }
}

final activitiesStateProvider = StateNotifierProvider<ActivitiesState, ActivitiesStateData>((ref) {
  return ActivitiesState(ref);
});

final activitiesProvider = Provider<List<MiittiActivity>>((ref) {
  return ref.watch(activitiesStateProvider).visibleActivities;
});

/// A class that represents the data of the ActivitiesState StateNotifier class.
class ActivitiesStateData {
  final List<MiittiActivity> activities;                        // A list of all activities in the state.
  final List<MiittiActivity> userActivities;                    // A list of activities created by the current user.
  final List<MiittiActivity> othersActivities;                  // A list of activities created by other users.
  final List<MiittiActivity> visibleActivities;                 // A list of activities that are currently visible on the map and list view.
  final List<MiittiActivity> requestedActivities;               // A list of activities where the current user has requested to join.
  final List<MiittiActivity> participatingActivities;           // A list of activities where the current user is a participant.
  final List<Tuple2<MiittiActivity, DateTime>> seenActivities;  // A list of activities whose latest updates the current user has seen.
  final SuperclusterMutableController clusterController;        // A SuperclusterMutableController used to cluster activities on the map.

  ActivitiesStateData({
    this.activities = const [],
    this.userActivities = const [],
    this.othersActivities = const [],
    this.visibleActivities = const [],
    this.requestedActivities = const [],
    this.participatingActivities = const [],
    this.seenActivities = const [],
    SuperclusterMutableController? clusterController,
  }) : clusterController = clusterController ?? SuperclusterMutableController();

  ActivitiesStateData copyWith({
    List<MiittiActivity>? activities,
    List<MiittiActivity>? userActivities,
    List<MiittiActivity>? othersActivities,
    List<MiittiActivity>? visibleActivities,
    List<MiittiActivity>? requestedActivities,
    List<MiittiActivity>? participatingActivities,
    List<Tuple2<MiittiActivity, DateTime>>? seenActivities,
    SuperclusterMutableController? clusterController,
  }) {
    return ActivitiesStateData(
      activities: activities ?? this.activities,
      userActivities: userActivities ?? this.userActivities,
      othersActivities: othersActivities ?? this.othersActivities,
      visibleActivities: visibleActivities ?? this.visibleActivities,
      requestedActivities: requestedActivities ?? this.requestedActivities,
      participatingActivities: participatingActivities ?? this.participatingActivities,
      seenActivities: seenActivities ?? this.seenActivities,
      clusterController: clusterController ?? this.clusterController,
    );
  }
}