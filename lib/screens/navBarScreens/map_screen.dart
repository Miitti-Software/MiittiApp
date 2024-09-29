import 'dart:async';
import 'dart:math';
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
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_list_tile.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/ad_banner.dart';
import 'package:miitti_app/widgets/data_containers/cluster_bubble.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/text_toggle_switch.dart';
import 'package:path_provider/path_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  SuperclusterMutableController clusterController = SuperclusterMutableController();
  final ScrollController _scrollController = ScrollController();
  Map<String, Marker> _markerMap = {};
  Timer? _debounce;
  double previousMaxScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMarkers();
    });
    _scrollController.addListener(_onScroll);
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

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final threshold = maxScrollExtent * 0.7;

    if (scrollPosition >= threshold && scrollPosition > previousMaxScrollPosition) {
      if (_debounce?.isActive ?? false) {
        _debounce?.cancel();
      } else {
        ref.read(activitiesStateProvider.notifier).loadMoreActivities();
      }

      previousMaxScrollPosition = max(scrollPosition, previousMaxScrollPosition);
      _debounce = Timer(const Duration(milliseconds: 200), () {
        _debounce = null;
      });
    }
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
        onTap: () {
          if (ref.watch(userStateProvider).isAnonymous) {
            BottomSheetDialog.show(
              context: context,
              title: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-title'),
              body: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-text'),
              confirmText: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-action-prompt'),
              onConfirmPressed: () {
                context.pop();
                context.push('/login/complete-profile/name');
              },
              cancelText: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-cancel'),
              onCancelPressed: () => context.pop(),
              disclaimer: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-disclaimer'),
            );
            return;
          }
          context.go('/activity/${activity.id}');
        },
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

  @override
  Widget build(BuildContext context) {
    final configStreamAsyncValue = ref.watch(remoteConfigStreamProvider);   // For some incomprehensible reason, configStreamProvider must be accessed here in order to not get stuck in a loading screen when signing out from a session started signed in, even though it is similarly accessed in the LoginIntroScreen where
    ref.listen(activitiesProvider, (_, __) => _updateMarkers());
    final config = ref.read(remoteConfigServiceProvider);
    int toggleIndex = ref.watch(mapStateProvider.select((state) => state.toggleIndex));
    ref.read(analyticsServiceProvider).logScreenView('map_screen');

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        showMap(),
        if (toggleIndex == 1) showOnList(),
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
                initialLabelIndex: toggleIndex,
                onToggle: (index) {
                  ref.read(mapStateProvider.notifier).setToggleIndex(index!);
                  if (index == 1) {
                    ref.read(analyticsServiceProvider).logScreenView('ActivitiesListView');
                    if (ref.read(adsStateProvider).isEmpty) {
                      ref.read(adsStateProvider.notifier).fetchAds();
                    }
                    if (ref.read(activitiesProvider).length < 6) {
                      ref.read(activitiesStateProvider.notifier).loadMoreActivities();  // Load only if there is not enough activities already to fill the first screen
                    }
                  }
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

Timer? _fullRefreshDebounce;

  Widget showOnList() {
    final activities = ref.watch(activitiesProvider);
    final ads = ref.watch(adsStateProvider);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        child: RefreshIndicator(
          onRefresh: () async {
            previousMaxScrollPosition = 0.0;
            final completer = Completer<void>();
            if (_fullRefreshDebounce?.isActive ?? false) {
              completer.complete();
              return completer.future;
            }
            _fullRefreshDebounce = Timer(const Duration(seconds: 3), () {});
            await ref.read(activitiesStateProvider.notifier).loadMoreActivities(fullRefresh: true);
            ref.read(adsStateProvider.notifier).shuffleAds();
            completer.complete();
            return completer.future;
          },
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: activities.length + ads.length,
            cacheExtent: 100,
            itemBuilder: (BuildContext context, int index) {
              
              // Determine if the current index should show an ad
              bool shouldShowAd = (index == 3) || ((index > 3) && ((index - 3) % 7 == 0));
              int adIndex = (index - 3) ~/ 7;

              if (shouldShowAd && adIndex < ads.length) {
                return AdBanner(adBannerData: ads[adIndex]);
              } else {
                int activityIndex = index - (index > 3 ? (adIndex + 1) : 0);
                if (activityIndex >= activities.length) {
                  // Show remaining ads if there are no more activities
                  int remainingAdIndex = index - activities.length;
                  if (remainingAdIndex < ads.length) {
                    return AdBanner(adBannerData: ads[remainingAdIndex]);
                  }
                  return const SizedBox.shrink(); // Prevent out of bounds error
                }
                return ActivityListTile(activities[activityIndex]);
              }
            },
          ),
        ),
      ),
    );
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