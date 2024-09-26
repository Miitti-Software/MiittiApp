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

class GeoQueryCondition {
  GeoQueryCondition({
    required this.radiusInKm,
    required this.center,
  });

  final double radiusInKm;
  final LatLng center;
}

class ActivitiesState extends StateNotifier<ActivitiesStateData> {
  ActivitiesState(this.ref) : super(ActivitiesStateData()) {
    _geoQueryCondition.stream.listen(_updateActivities);
    _initializeFirestoreListener();
  }

  final Ref ref;
  Timer? _debounce;
  final _geoQueryCondition = BehaviorSubject<GeoQueryCondition>.seeded(
    GeoQueryCondition(
      radiusInKm: 1.0,
      center: const LatLng(60.1699, 24.9325),
    ),
  );
  bool _isLoadingMore = false;

  void _initializeFirestoreListener() {
    if (ref.read(userStateProvider).isAnonymous) return;
    final firestoreService = ref.read(firestoreServiceProvider);
    firestoreService.streamUserCreatedActivities().listen((updatedActivities) {
      _updateRequestsAndParticipants(updatedActivities);
    });
  }

  void updateGeoQueryCondition(LatLng center, double zoom) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final radiusInKm = calculateRadius(zoom, degree: center.latitude);
      _geoQueryCondition.add(GeoQueryCondition(center: center, radiusInKm: radiusInKm));
    });
  }

  double calculateRadius(
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
        updateState();
      }
    });
  }

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
      updateState();
    }
  }

  Future<void> loadMoreActivities({bool fullRefresh = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    if (fullRefresh) {
      state = state.copyWith(activities: []);
      updateState();
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    List<MiittiActivity> newActivities = await firestoreService.fetchFilteredActivities(pageSize: 10, fullRefresh: fullRefresh);

    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (filteredActivities.isNotEmpty) {
      state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
    }

    _isLoadingMore = false;
    updateState();
  }

  Future<void> loadMoreParticipatingActivities({bool fullRefresh = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    if (fullRefresh) {
      state = state.copyWith(activities: []);
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    List<MiittiActivity> newActivities = await firestoreService.fetchParticipatingActivities(pageSize: 10, fullRefresh: fullRefresh);

    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (filteredActivities.isNotEmpty) {
      state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
    }

    _isLoadingMore = false;
    updateState();
  }

  void markSeenLocally(MiittiActivity activity) {
    final seenActivity = Tuple2(activity, DateTime.now());
    if (!state.seenActivities.any((tuple) => tuple.item1.id == activity.id)) {
      state = state.copyWith(seenActivities: [...state.seenActivities, seenActivity]);
    }
  }

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

      updateState();
      return true;
    } catch (e) {
      debugPrint('Error updating activities data: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(MiittiActivity activity) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteActivity(activity.id);
      state = state.copyWith(activities: state.activities.where((a) => a.id != activity.id).toList());
      updateState();
      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }

Future<bool> leaveActivity(MiittiActivity activity) async {
  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    activity.removeParticipant(ref.read(userStateProvider).data.toMiittiUser());
    await firestoreService.updateActivity(activity.toMap(), activity.id, activity is CommercialActivity);
    ref.read(userStateProvider.notifier).decrementActivitiesJoined();
    state = state.copyWith(activities: state.activities.map((a) => a.id == activity.id ? activity : a).toList());
    updateState();
    return true;
  } catch (e) {
    debugPrint('Error leaving activity: $e');
    return false;
  }
}

Future<bool> removeParticipant(UserCreatedActivity activity, MiittiUser user) async {
  try {
    if (user.uid == activity.creator) return false;
    final firestoreService = ref.read(firestoreServiceProvider);
    final updatedActivity = activity.removeParticipant(user);
    await firestoreService.updateActivity(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
    state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
    updateState();
    return true;
  } catch (e) {
    debugPrint('Error removing participant: $e');
    return false;
  }
}

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
    updateState();
    return true;
  } catch (e) {
    debugPrint('Error joining activity: $e');
    return false;
  }
}

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
    updateState();
    return true;
  } catch (e) {
    debugPrint('Error requesting to join activity: $e');
    return false;
  }
}

Future<bool> acceptRequest(String activityId, MiittiUser user) async {
  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    final activity = state.activities.firstWhere((a) => a.id == activityId) as UserCreatedActivity;
    final updatedActivity = activity.addParticipant(user);
    final success = await firestoreService.updateActivity(updatedActivity.notifyParticipants().markSeen(ref.read(userStateProvider).uid!).toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
    if (!success) return false;
    ref.read(notificationServiceProvider).sendRequestAcceptedNotification(updatedActivity);
    state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
    updateState();
    return true;
  } catch (e) {
    debugPrint('Error accepting request: $e');
    return false;
  }
}

  Future<bool> declineRequest(String activityId, String userId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final activity = state.activities.firstWhere((a) => a.id == activityId) as UserCreatedActivity;
      final updatedActivity = activity.removeRequest(userId);
      final success = await firestoreService.updateActivity(updatedActivity.toMap(), updatedActivity.id, updatedActivity is CommercialActivity);
      if (!success) return false;
      state = state.copyWith(activities: state.activities.map((a) => a.id == updatedActivity.id ? updatedActivity : a).toList());
      updateState();
      return true;
    } catch (e) {
      debugPrint('Error declining request: $e');
      return false;
    }
  }

  bool hasNewActivityUpdates(String userId) {
    return state.activities.any((activity) {
      final isParticipant = activity.participants.contains(userId);
      final lastSeen = activity.participantsInfo[userId]?['lastSeen'];
      final condition = state.seenActivities.any((tuple) => tuple.item1.id == activity.id && tuple.item2.isAfter(activity.latestActivity));
      return isParticipant && (lastSeen == null && !condition || lastSeen != null && (activity.latestActivity.isAfter(lastSeen)) && !condition);
    });
  }

  void updateState() {
    final userState = ref.read(userStateProvider);
    if (!userState.isAnonymous) {
      final userId = ref.read(userStateProvider).uid!;
      final List<MiittiActivity> userActivities = [];
      final List<MiittiActivity> othersActivities = [];
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
      }

      state = state.copyWith(
        userActivities: userActivities,
        othersActivities: othersActivities,
        participatingActivities: participatingActivities,
      );
    }
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
  return ref.watch(activitiesStateProvider).activities;
});

class ActivitiesStateData {
  final List<MiittiActivity> activities;
  final List<MiittiActivity> userActivities;
  final List<MiittiActivity> othersActivities;
  final List<MiittiActivity> requestedActivities;
  final List<MiittiActivity> participatingActivities;
  final List<Tuple2<MiittiActivity, DateTime>> seenActivities;
  final SuperclusterMutableController clusterController;

  ActivitiesStateData({
    this.activities = const [],
    this.userActivities = const [],
    this.othersActivities = const [],
    this.requestedActivities = const [],
    this.participatingActivities = const [],
    this.seenActivities = const [],
    SuperclusterMutableController? clusterController,
  }) : clusterController = clusterController ?? SuperclusterMutableController();

  ActivitiesStateData copyWith({
    List<MiittiActivity>? activities,
    List<MiittiActivity>? userActivities,
    List<MiittiActivity>? othersActivities,
    List<MiittiActivity>? requestedActivities,
    List<MiittiActivity>? participatingActivities,
    List<Tuple2<MiittiActivity, DateTime>>? seenActivities,
    SuperclusterMutableController? clusterController,
  }) {
    return ActivitiesStateData(
      activities: activities ?? this.activities,
      userActivities: userActivities ?? this.userActivities,
      othersActivities: othersActivities ?? this.othersActivities,
      requestedActivities: requestedActivities ?? this.requestedActivities,
      participatingActivities: participatingActivities ?? this.participatingActivities,
      seenActivities: seenActivities ?? this.seenActivities,
      clusterController: clusterController ?? this.clusterController,
    );
  }
}