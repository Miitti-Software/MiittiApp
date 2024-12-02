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
    firestoreService.streamCommercialActivities().listen((updatedActivities) {
      _updateCommercialActivities(updatedActivities);
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

  void _updateCommercialActivities(List<CommercialActivity> updatedActivities) {
    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final updatedStateActivities = state.activities.map((activity) {
      if (activity is CommercialActivity) {
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

  /// Returns a stream corresponding to the activity with the given ID.
  Stream<MiittiActivity?> streamActivity(String activityId) {
    final firestoreService = ref.read(firestoreServiceProvider);
    
    return firestoreService
      .streamActivity(activityId)
      .map((activity) async {
        return activity;
      })
      .asyncMap((futureActivity) async => await futureActivity);
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

  /// Updates the last seen time of the current user in the given activity.
  Future<void> markActivityAsSeen(MiittiActivity activity) async {
    final userState = ref.read(userStateProvider);
    final somethingToSee = activity.latestActivity.isAfter(activity.participantsInfo[userState.uid]?['lastSeen'] ?? DateTime(2020)) || activity.participantsInfo[userState.uid]?['lastSeen'] != null;
    if (userState.isAnonymous || !activity.participants.contains(userState.uid) || !somethingToSee) return;
    final userId = userState.uid!;
    final firestoreService = ref.read(firestoreServiceProvider);
    final updatedActivity = activity.markSeen(userId);
    Map<String, dynamic> fieldsToUpdate = {
      'participantsInfo.$userId.lastSeen': updatedActivity.latestActivity,
    };
    await firestoreService.updateActivityFields(fieldsToUpdate, updatedActivity.id, updatedActivity is CommercialActivity);
    state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
    _updateState();
  }

  /// Updates the last opened chat time of the current user in the given activity.
  Future<void> markChatAsRead(MiittiActivity activity, String messageId) async {
    final userState = ref.read(userStateProvider);
    final somethingToSee = activity.latestMessage?.isAfter(activity.participantsInfo[userState.uid]?['lastOpenedChat'] ?? DateTime(2020));
    if (userState.isAnonymous || !activity.participants.contains(userState.uid) || !somethingToSee!) return;
    final userId = userState.uid!;
    final firestoreService = ref.read(firestoreServiceProvider);
    final updatedActivity = activity.markMessageRead(userId, messageId);
    Map<String, dynamic> fieldsToUpdate = {
      'participantsInfo.$userId.lastReadMessage': updatedActivity.toMap()['participantsInfo'][userId]['lastReadMessage'],
      'participantsInfo.$userId.lastOpenedChat': updatedActivity.latestMessage,
      'participantsInfo.$userId.lastSeen': updatedActivity.latestMessage,
    };
    await firestoreService.updateActivityFields(fieldsToUpdate, updatedActivity.id, updatedActivity is CommercialActivity);
    state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
    _updateState();
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

  /// Archives an activity in Firestore and removes it from the state of the ActivitiesState StateNotifier.
  Future<bool> archiveActivity(MiittiActivity activity) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final updatedActivity = activity.updateEndTime(DateTime.now());
      await firestoreService.updateActivityTransaction(updatedActivity.toMap(), activity.id, activity is CommercialActivity);
      state = state.copyWith(activities: state.activities.where((a) => a.id != activity.id).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error archiving activity: $e');
      return false;
    }
  }

  /// Remove the current user from the participants list of the given activity.
  Future<bool> leaveActivity(MiittiActivity activity) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      activity.removeParticipant(ref.read(userStateProvider).data.toMiittiUser());
      await firestoreService.updateActivityTransaction(activity.toMap(), activity.id, activity is CommercialActivity);
      ref.read(userStateProvider.notifier).decrementActivitiesJoined();
      state = state.copyWith(activities: state.activities.map((a) => a.id == activity.id ? activity : a).toList());
      _updateState();
      if (activity is UserCreatedActivity) {
        ref.read(notificationServiceProvider).sendCancelNotification(activity);
      }
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
      await firestoreService.updateActivityTransaction(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
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
      final success = await firestoreService.updateActivityTransaction(updatedActivity.markSeen(userState.uid!).toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
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
      if (userState.isAnonymous || activity.participants.contains(userState.uid)) {
        return false;
      }
      final firestoreService = ref.read(firestoreServiceProvider);
      UserCreatedActivity updatedActivity = activity.addRequest(ref.read(userStateProvider).uid!);
      final success = await firestoreService.updateActivityTransaction(updatedActivity.toMap(), updatedActivity.id, activity is CommercialActivity);
      if (!success) return false;
      ref.read(userStateProvider.notifier).incrementActivitiesJoined();
      ref.read(analyticsServiceProvider).logActivityJoined(updatedActivity, ref.read(userStateProvider).data.toMiittiUser());
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      ref.read(notificationServiceProvider).sendRequestNotification(updatedActivity);
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
      final success = await firestoreService.updateActivityTransaction(updatedActivity.markSeen(ref.read(userStateProvider).uid!).toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      ref.read(notificationServiceProvider).sendRequestAcceptedNotification(updatedActivity, user);
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
      final success = await firestoreService.updateActivityTransaction(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      _updateState();
      return true;
    } catch (e) {
      debugPrint('Error declining request: $e');
      return false;
    }
  }

  bool hasNewMessages(String userId) {
    return state.activities.any((activity) {
      final isParticipant = activity.participants.contains(userId);
      final lastSeen = activity.participantsInfo[userId]?['lastOpenedChat'];
      final hasMessage = activity.latestMessage != null && activity.latestMessage!.isAfter(lastSeen ?? DateTime(2020));
      final isNew = lastSeen == null || (lastSeen != null && (activity.latestActivity.isAfter(lastSeen)));
      return isParticipant && hasMessage && isNew;
    });
  }

  bool hasNewJoin(String userId) {
    return state.activities.any((activity) {
      final isParticipant = activity.participants.contains(userId);
      final lastSeen = activity.participantsInfo[userId]?['lastSeen'];
      final hasJoin = activity.latestJoin != null && activity.latestJoin!.isAfter(lastSeen ?? DateTime(2020));
      final isNew = lastSeen == null || (lastSeen != null && (activity.latestActivity.isAfter(lastSeen)));
      return isParticipant && hasJoin && isNew && activity is UserCreatedActivity;
    });
  }

  bool hasRequests(String userId) {
    return state.activities.any((activity) {
      final isParticipant = activity.participants.contains(userId);
      final isCreator = activity.creator == userId;
      final hasRequest = activity is UserCreatedActivity && activity.requests.isNotEmpty;
      return isParticipant && isCreator && hasRequest;
    });
  }

  bool hasNotifications(String userId) {
    return hasNewMessages(userId) || hasNewJoin(userId) || hasRequests(userId);
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
  final SuperclusterMutableController clusterController;        // A SuperclusterMutableController used to cluster activities on the map.

  ActivitiesStateData({
    this.activities = const [],
    this.userActivities = const [],
    this.othersActivities = const [],
    this.visibleActivities = const [],
    this.requestedActivities = const [],
    this.participatingActivities = const [],
    SuperclusterMutableController? clusterController,
  }) : clusterController = clusterController ?? SuperclusterMutableController();

  ActivitiesStateData copyWith({
    List<MiittiActivity>? activities,
    List<MiittiActivity>? userActivities,
    List<MiittiActivity>? othersActivities,
    List<MiittiActivity>? visibleActivities,
    List<MiittiActivity>? requestedActivities,
    List<MiittiActivity>? participatingActivities,
    SuperclusterMutableController? clusterController,
  }) {
    return ActivitiesStateData(
      activities: activities ?? this.activities,
      userActivities: userActivities ?? this.userActivities,
      othersActivities: othersActivities ?? this.othersActivities,
      visibleActivities: visibleActivities ?? this.visibleActivities,
      requestedActivities: requestedActivities ?? this.requestedActivities,
      participatingActivities: participatingActivities ?? this.participatingActivities,
      clusterController: clusterController ?? this.clusterController,
    );
  }
}

// TODO: Make sure that all activities with activity (notifications) are always loaded into the state