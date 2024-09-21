import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:rxdart/rxdart.dart';

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
      }
    });
  }

  Future<void> loadMoreActivities({bool fullRefresh = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    if (fullRefresh) {
      state = state.copyWith(activities: []);
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    List<MiittiActivity> newActivities = await firestoreService.fetchFilteredActivities(pageSize: 10, fullRefresh: fullRefresh);

    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (filteredActivities.isNotEmpty) {
      state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
    }

    _isLoadingMore = false;
  }

  Future<void> deleteActivity(String activityId) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.deleteActivity(activityId);
    state = state.copyWith(activities: state.activities.where((activity) => activity.id != activityId).toList());
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
  final SuperclusterMutableController clusterController;

  ActivitiesStateData({
    this.activities = const [],
    SuperclusterMutableController? clusterController,
  }) : clusterController = clusterController ?? SuperclusterMutableController();

  ActivitiesStateData copyWith({
    List<MiittiActivity>? activities,
    SuperclusterMutableController? clusterController,
  }) {
    return ActivitiesStateData(
      activities: activities ?? this.activities,
      clusterController: clusterController ?? this.clusterController,
    );
  }
}