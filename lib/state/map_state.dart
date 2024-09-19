import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

// GeoQueryCondition class
class GeoQueryCondition {
  GeoQueryCondition({
    required this.radiusInKm,
    required this.center,
  });

  final double radiusInKm;
  final LatLng center;
}

// MapStateData class
class MapStateData {
  final LatLng location;
  final double zoom;
  final List<AdBannerData> ads;
  final int showOnMap;
  MapStateData({
    this.location = const LatLng(60.1699, 24.9325),
    this.zoom = 13.0,
    this.ads = const [],
    this.showOnMap = 0,
  });

  MapStateData copyWith({
    LatLng? location,
    double? zoom,
    List<AdBannerData>? ads,
    int? showOnMap,
  }) {
    return MapStateData(
      location: location ?? this.location,
      zoom: zoom ?? this.zoom,
      ads: ads ?? this.ads,
      showOnMap: showOnMap ?? this.showOnMap,
    );
  }
}


// MapState class
class MapState extends StateNotifier<MapStateData> {
  MapState(this.ref) : super(MapStateData()) {
    initializeUserData();
  }

  final Ref ref;

  void initializeUserData() {
    final userData = ref.read(userStateProvider).data;
    final config = ref.read(remoteConfigServiceProvider);
    final latitude = userData.areas.isNotEmpty ? config.get<Map<String, dynamic>>(userData.areas[0])['latitude'] as double : 60.1699;
    final longitude = userData.areas.isNotEmpty ? config.get<Map<String, dynamic>>(userData.areas[0])['longitude'] as double : 24.9325;
    state = state.copyWith(
      location: userData.latestLocation ?? LatLng(latitude, longitude),
    );
  }

  void fetchAds() async {
    List<AdBannerData> ads = await ref.read(firestoreServiceProvider).fetchAdBanners();
    state = state.copyWith(ads: ads);
    if (ads.isNotEmpty) {
      ref.read(firestoreServiceProvider).addAdView(ads[0].id); // TODO: Do something smarter
    }
  }

  void setShowOnMap(int index) {
    state = state.copyWith(showOnMap: index);
    if (index == 1) {
      fetchAds();
    }
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void setLocation(LatLng location) {
    state = state.copyWith(location: location);
  }
}

final mapStateProvider = StateNotifierProvider<MapState, MapStateData>((ref) {
  return MapState(ref);
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

class ActivitiesState extends StateNotifier<ActivitiesStateData> {
  ActivitiesState(this.ref) : super(ActivitiesStateData()) {
    _geoQueryCondition.stream.listen(_updateActivities);
  }

  final Ref ref;
  LatLng? lastFetchedLocation;
  double? lastFetchedRadius;
  final _geoQueryCondition = BehaviorSubject<GeoQueryCondition>.seeded(
    GeoQueryCondition(
      radiusInKm: 1.0,
      center: LatLng(60.1699, 24.9325),
    ),
  );

  void updateGeoQueryCondition(LatLng center, double radiusInKm) {
  final distance = Distance().as(LengthUnit.Kilometer, center, lastFetchedLocation ?? center);

  if (lastFetchedLocation == null || distance > radiusInKm) {
    _geoQueryCondition.add(GeoQueryCondition(center: center, radiusInKm: radiusInKm));
    lastFetchedLocation = center;
    lastFetchedRadius = radiusInKm;
  }
}

void _updateActivities(GeoQueryCondition geoQueryCondition) {
  final firestoreService = FirebaseFirestore.instance;
  final geoCollectionReference = GeoCollectionReference(firestoreService.collection('activities'));

  geoCollectionReference.subscribeWithin(
    center: GeoFirePoint(GeoPoint(geoQueryCondition.center.latitude, geoQueryCondition.center.longitude)),
    radiusInKm: geoQueryCondition.radiusInKm,
    field: 'location',
    geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
    strictMode: true,
  ).listen((documentSnapshots) {
    final newActivities = documentSnapshots.map((doc) {
      return UserCreatedActivity.fromFirestore(doc);
    }).toList();

    final currentActivityIds = state.activities.map((activity) => activity.id).toSet();
    final filteredActivities = newActivities.where((activity) => !currentActivityIds.contains(activity.id)).toList();

    if (filteredActivities.isNotEmpty) {
      state = state.copyWith(activities: state.activities.followedBy(filteredActivities).toList());
      updateClusterMarkers();
      print('State Activities updated: ${state.activities}');
      print('New Activities added: ${filteredActivities}');
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
    super.dispose();
  }
}

final activitiesStateProvider = StateNotifierProvider<ActivitiesState, ActivitiesStateData>((ref) {
  return ActivitiesState(ref);
});

final activitiesProvider = Provider<List<MiittiActivity>>((ref) {
  return ref.watch(activitiesStateProvider).activities;
});