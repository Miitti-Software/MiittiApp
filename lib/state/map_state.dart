import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';

// MapStateData class
class MapStateData {
  final LatLng location;
  final double zoom;
  final double previousZoom;
  final List<AdBannerData> ads;
  final int toggleIndex;
  MapStateData({
    this.location = const LatLng(60.1699, 24.9325),
    this.zoom = 13.0,
    this.previousZoom = 13.0,
    this.ads = const [],
    this.toggleIndex = 0,
  });

  MapStateData copyWith({
    LatLng? location,
    double? zoom,
    double? previousZoom,
    List<AdBannerData>? ads,
    int? toggleIndex,
  }) {
    return MapStateData(
      location: location ?? this.location,
      zoom: zoom ?? this.zoom,
      previousZoom: previousZoom ?? this.previousZoom,
      ads: ads ?? this.ads,
      toggleIndex: toggleIndex ?? this.toggleIndex,
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
    ads.shuffle();
    state = state.copyWith(ads: ads);
  }

  void setShowOnMap(int index) {
    state = state.copyWith(toggleIndex: index);
    if (index == 1) {
      fetchAds();
    }
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void saveZoom(double zoom) {
    state = state.copyWith(previousZoom: zoom);
  }

  void restoreZoom() {
    state = state.copyWith(zoom: state.previousZoom);
  }

  void setLocation(LatLng location) {
    state = state.copyWith(location: location);
  }

  void setToggleIndex(int index) {
    state = state.copyWith(toggleIndex: index);
  }
}

final mapStateProvider = StateNotifierProvider<MapState, MapStateData>((ref) {
  return MapState(ref);
});