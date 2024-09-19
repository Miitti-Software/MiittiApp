import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
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

  void updateGeoQueryCondition(LatLng center, double zoom) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final radiusInKm = calculateRadius(zoom, degree: center.latitude);
      _geoQueryCondition.add(GeoQueryCondition(center: center, radiusInKm: radiusInKm));
    });
  }

  double calculateRadius(
    double zoom, {
    double mapLongSidePixels = 500,
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
        updateClusterMarkers();
      }
    });
  }

  void updateClusterMarkers() {
    final markers = state.activities.map((activity) {
      return Marker(
        width: 100.0,
        height: 100.0,
        point: LatLng(activity.latitude, activity.longitude),
        child: GestureDetector(
          onTap: () {
            // Handle marker tap
          },
          child: activity is UserCreatedActivity ? ActivityMarker(activity: activity) : CommercialActivityMarker(activity: activity),
        ),
      );
    }).toList();
    state.clusterController.replaceAll(markers);
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

// ActivitiesState class
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