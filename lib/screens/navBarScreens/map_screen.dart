//TODO: Refactor

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
//import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/ad_banner.dart';
import 'package:miitti_app/widgets/data_containers/cluster_bubble.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/text_toggle_switch.dart';
import 'package:path_provider/path_provider.dart';
import 'package:miitti_app/constants/app_style.dart';


// TODO: Cache the map tiles
// TODO: Cache the loaded activities and access the cached ones with activity details
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  List<AdBannerData> _ads = [];
  SuperclusterMutableController clusterController = SuperclusterMutableController();
  Map<String, Marker> _markerMap = {};
  int showOnMap = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMarkers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateUserLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeMarkers() {
    final activities = ref.read(activitiesProvider);
    final newMarkers = {
      for (var activity in activities)
        activity.id: _createMarker(activity)
    };
    _markerMap = newMarkers;
    clusterController.replaceAll(_markerMap.values.toList());
  }

  void _updateMarkers() {
    final activities = ref.read(activitiesProvider);
    final currentIds = _markerMap.keys.toSet();
    final newIds = activities.map((a) => a.id).toSet();

    // Remove markers for activities that no longer exist
    for (final id in currentIds.difference(newIds)) {
      final marker = _markerMap.remove(id);
      if (marker != null) {
        clusterController.remove(marker);
      }
    }

    // Add or update markers for new or existing activities
    for (final activity in activities) {
      if (!_markerMap.containsKey(activity.id)) {
        final marker = _createMarker(activity);
        _markerMap[activity.id] = marker;
        clusterController.add(marker);
      }
    }
  }

  Marker _createMarker(MiittiActivity activity) {
    return Marker(
      width: 100.0,
      height: 100.0,
      point: LatLng(activity.latitude, activity.longitude),
      child: GestureDetector(
        onTap: () => context.go('/activity/${activity.id}'),
        child: activity is UserCreatedActivity
          ? ActivityMarker(activity: activity)
          : CommercialActivityMarker(activity: activity),
      ),
    );
  }

  void updateUserLocation() async {
    final config = ref.read(remoteConfigServiceProvider);
    final locationPermission = ref.read(locationPermissionProvider.notifier);
    bool serviceEnabled = locationPermission.serviceEnabled;
    bool permissionGranted = ref.watch(locationPermissionProvider);

    if (!serviceEnabled) {
      if (!permissionGranted) {
        permissionGranted = await locationPermission.requestLocationPermission();
        if (!permissionGranted) {
          if (mounted) {
            ErrorSnackbar.show(context, config.get<String>('location-permission-denied'));
          }
          return;
        }
      }

      bool locationUpdated = await ref.read(userStateProvider.notifier).updateLocation();

      if (locationUpdated) {
        final userLocation = ref.read(userStateProvider).data.latestLocation;
        if (userLocation != null) {
          ref.read(mapStateProvider.notifier).setLocation(userLocation);
        }
      }
    }
  }

  void fetchAds() async {
    List<AdBannerData> ads = await ref.read(firestoreServiceProvider).fetchAdBanners();
    setState(() {
      _ads = ads;
    });
    if (_ads.isNotEmpty) {
      ref.read(firestoreServiceProvider).addAdView(_ads[0].id); // TODO: Do something smarter
    }
  }

  @override
  Widget build(BuildContext context) {
    final configStreamAsyncValue = ref.watch(remoteConfigStreamProvider);   // For some incomprehensible reason, configStreamProvider must be accessed here in order to not get stuck in a loading screen when signing out from a session started signed in, even though it is similarly accessed in the LoginIntroScreen where
    ref.listen(activitiesProvider, (_, __) => _updateMarkers());
    final config = ref.read(remoteConfigServiceProvider);

    return Stack(
      children: [
        showOnMap == 1 ? showOnList() : showMap(),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 36,
              width: 250,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.minVerticalPadding, vertical: AppSizes.minVerticalPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(215),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextToggleSwitch(
                label1: config.get<String>('toggle-show-map'),
                label2: config.get<String>('toggle-show-list'),
                initialLabelIndex: showOnMap,
                onToggle: (index) {
                  setState(() {
                    showOnMap = index!;
                    if (index == 1) {
                      fetchAds();
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget showMap() {
    final location = ref.watch(mapStateProvider.select((state) => state.location));
    final zoom = ref.watch(mapStateProvider.select((state) => state.zoom));
    return FutureBuilder(
      future: getPath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return FlutterMap(
          options: MapOptions(
            keepAlive: true,
            backgroundColor: const Color(0xFFe4dedd),
            initialCenter: location,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            minZoom: 5.0,
            maxZoom: 18.0,
            onMapReady: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(activitiesStateProvider.notifier).updateGeoQueryCondition(location, zoom);
              });
            },
            onPositionChanged: (position, hasGesture) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(activitiesStateProvider.notifier).updateGeoQueryCondition(position.center!, position.zoom!);
                ref.read(mapStateProvider.notifier).saveZoom(position.zoom!);
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://api.mapbox.com/styles/v1/miittiapp/clt1ytv8s00jz01qzfiwve3qm/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
              additionalOptions: const {
                'accessToken': mapboxAccess,
              },
              tileProvider: CustomTileProvider(
                cacheManager: MapTilesCacheManager().instance,
              ),
              keepBuffer: 20,
              panBuffer: 2,
            ),
            Consumer(
              builder: (context, ref, child) {
                return SuperclusterLayer.mutable(
                  controller: clusterController,
                  initialMarkers: _markerMap.values.toList(),
                  clusterWidgetSize: const Size(100.0, 100.0),
                  maxClusterRadius: 205,
                  builder: (context, position, markerCount, extraClusterData) => ClusterBubble(markerCount: markerCount),
                );
              },
            ),
          ],
        );
      },
    );
  }


  Widget showOnList() {
    final activities = ref.watch(activitiesProvider);
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/blurredMap.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: const EdgeInsets.only(top: 60),
          child: ListView.builder(
            itemCount: activities.length + (_ads.isNotEmpty ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == 1 && _ads.isNotEmpty) {
                return AdBanner(adBannerData: _ads[0]);
              } else {
                int activityIndex = _ads.isNotEmpty && index > 1 ? index - 1 : index;

                MiittiActivity activity = activities[activityIndex];
                String activityAddress = activity.address;

                List<String> addressParts = activityAddress.split(',');
                String cityName = addressParts[0].trim();

                int participants = activity.participantsInfo.isEmpty ? 0 : activity.participantsInfo.length;

                return InkWell(
                  onTap: () => context.go('/activity/${activity.id}'), // TODO: Don't let the user go to the activity details page from map screen if they are not signed in - deep link is okay
                  child: Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    margin: const EdgeInsets.all(10.0),
                    child: Container(
                      height: 125,
                      decoration: BoxDecoration(
                        color: AppStyle.black.withOpacity(0.8),
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Activity.getSymbol(activity),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    activity.title,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  cityName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '$participants participants',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  int getPlaces(double zoomLevel) {
    final zoomToDecimalPlaces = {
      20.0: 9, // Very close view, high precision
      19.0: 8,
      18.0: 7,
      17.0: 6,
      16.0: 5,
      15.0: 4,
      14.0: 3, // Medium zoom level
      13.0: 2,
      12.0: 2,
      11.0: 2,
      10.0: 2,
      9.0: 1, // Medium to high zoom level
      8.0: 1,
      7.0: 1,
      6.0: 1,
      5.0: 0, // Lower zoom level, less precision
      4.0: 0,
      3.0: 0,
    };

    return zoomToDecimalPlaces[zoomLevel.roundToDouble()] ?? 0;
  }

  Future<String> getPath() async {
    final directory = await getApplicationCacheDirectory();
    return directory.path;
  }
}

class CustomTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;

  CustomTileProvider({required this.cacheManager});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(url, cacheManager: cacheManager);
  }

  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    return options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{accessToken}', mapboxAccess);
  }
}