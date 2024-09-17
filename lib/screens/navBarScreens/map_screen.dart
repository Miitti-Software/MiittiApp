//TODO: Refactor

import 'dart:ui';

import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/screens/activity_details_page.dart';
//import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:miitti_app/screens/commercialScreens/comact_detailspage.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/ad_banner.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
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
  // late LatLng location;   // TODO: Move to global state
  // double zoom = 13.0;

  List<MiittiActivity> _activities = [];
  List<AdBannerData> _ads = [];

  SuperclusterMutableController clusterController = SuperclusterMutableController();

  int showOnMap = 0;

  @override
  void initState() {
    super.initState();
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

  void updateUserLocation() async {
    final config = ref.read(remoteConfigServiceProvider);
    final locationPermission = ref.read(locationPermissionProvider.notifier);
    bool serviceEnabled = locationPermission.serviceEnabled;
    bool permissionGranted = ref.watch(locationPermissionProvider);

    if (!serviceEnabled) {
      serviceEnabled = await locationPermission.requestLocationService();
      if (!serviceEnabled) {
        if (mounted) {
          ErrorSnackbar.show(context, config.get<String>('location-service-disabled'));
        }
        return;
      }
    }

    if (!permissionGranted) {
      permissionGranted = await locationPermission.requestLocationPermission();
      if (!permissionGranted) {
        if (mounted) {
          ErrorSnackbar.show(context, config.get<String>('location-permission-denied'));
        }
        return;
      }
    }

    print('user location before update ${ref.read(userStateProvider).data.latestLocation}');

    bool locationUpdated = await ref.read(userStateProvider.notifier).updateLocation();

    // print('user location immediately after update ${ref.read(userStateProvider).data.latestLocation}');

    if (locationUpdated) {
      final userLocation = ref.read(userStateProvider).data.latestLocation;
      print('User location: $userLocation');
      if (userLocation != null) {
        print('map location before update ${ref.read(mapStateProvider).location}');
        ref.read(mapStateProvider.notifier).setLocation(userLocation);
        print('map location after update ${ref.read(mapStateProvider).location}');
      }
    }

    /*myCameraPosition = CameraPosition(
      target: currentLatLng,
      zoom: 12,
      tilt: 0,
      bearing: 0,
    );

    if (controller != null) {
      controller
          .animateCamera(CameraUpdate.newCameraPosition(myCameraPosition));
    }*/
  }

  // void fetchActivities() async {
  //   List<MiittiActivity> activities = await ref.read(firestoreServiceProvider).fetchFilteredActivities();
  //   if (mounted) {
  //     setState(() {
  //       _activities = activities.toList();
  //     });
  //     clusterController.addAll(_activities.map(activityMarker).toList());
  //     // addGeojsonCluster(controller, _activities);
  //   }
  // }

  Marker activityMarker(MiittiActivity activity) {
    return Marker(
      width: 100.0,
      height: 100.0,
      point: LatLng(activity.latitude, activity.longitude),
      child: GestureDetector(
        onTap: () {
          // TODO: Switch to GoRouter
          // goToActivityDetailsPage(activity);  // TODO: Refactor
          context.go('/activity/${activity.id}');
        },
        child: activity is UserCreatedActivity ? ActivityMarker(activity: activity) : CommercialActivityMarker(activity: activity),
      ),
    );
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

  // // TODO: Delete when redundant
  // goToActivityDetailsPage(MiittiActivity activity) {
  //   final mapState = ref.watch(mapStateProvider.notifier);
  //   mapState.setLocation(LatLng(activity.latitude - 0.001, activity.longitude));
  //   mapState.setZoom(17.0);

  //   // TODO: Don't let the user go to the activity details page from map screen if they are not signed in - deep link is okay
  //   context.go('/activity/${activity.id}');
  // }

  // TODO: Don't let the user create an activity from the map screen if they are not signed in
  // TODO: Do let the user see commercial activity details from the map screen

  @override
  Widget build(BuildContext context) {
    final configStreamAsyncValue = ref.watch(remoteConfigStreamProvider);   // For some incomprehensible reason, configStreamProvider must be accessed here in order to not get stuck in a loading screen when signing out from a session started signed in, even though it is similarly accessed in the LoginIntroScreen where 
    final activitiesStream = ref.watch(activitiesStreamProvider);

    return Stack(
      children: [
        showOnMap == 1 ? showOnList() : showMap(activitiesStream),
        //top switch
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              width: 260,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppStyle.black.withOpacity(0.8),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: mapToggleSwitch(
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

  Widget showMap(AsyncValue<List<MiittiActivity>> activitiesStream) {
    final mapState = ref.watch(mapStateProvider);
    return activitiesStream.when(
      data: (activities) {
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
                backgroundColor: AppStyle.black,
                initialCenter: mapState.location,
                initialZoom: mapState.zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
                minZoom: 5.0,
                maxZoom: 18.0,
                onMapReady: () {},
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/miittiapp/clt1ytv8s00jz01qzfiwve3qm/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                  additionalOptions: const {
                    'accessToken': mapboxAccess,
                  },
                  tileProvider: CachedTileProvider(
                    store: HiveCacheStore(
                      snapshot.data.toString(),
                    ),
                  ),
                ),
                SuperclusterLayer.mutable(
                  controller: clusterController,
                  initialMarkers: activities.map(activityMarker).toList(),
                  onMarkerTap: (marker) {
                    Widget child = marker.child;
                    if (child is GestureDetector) {
                      child.onTap!();
                    }
                  },
                  clusterWidgetSize: const Size(100.0, 100.0),
                  maxClusterRadius: 205,
                  builder: (context, position, markerCount, extraClusterData) => Center(
                    child: Stack(alignment: Alignment.center, children: [
                      Image.asset(
                        "images/circlebackground.png",
                      ),
                      Positioned(
                        top: 20,
                        child: Text(
                          "$markerCount",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontFamily: "Rubik",
                          ),
                        ),
                      )
                    ]),
                  ),
                  indexBuilder: IndexBuilders.rootIsolate,
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Widget showOnList() {
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
          child: Consumer(
            builder: (context, watch, child) {
              final activitiesStream = ref.watch(activitiesStreamProvider);
              return activitiesStream.when(
                data: (activities) {
                  return ListView.builder(
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          cityName,
                                          style: Theme.of(context).textTheme.labelMedium,
                                        ),
                                        Text(
                                          '$participants participants',
                                          style: Theme.of(context).textTheme.labelMedium,
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
              );
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
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }





  /*CameraPosition myCameraPosition = CameraPosition(
    target: LatLng(60.1699, 24.9325),
    zoom: 12,
    bearing: 0,
  );*/

  //late MapboxMapController controller;


  /*static Future<void> addGeojsonCluster(
    MapboxMapController controller,
    List<MiittiActivity> myActivities,
  ) async {
    final List<Map<String, dynamic>> features = myActivities.map((activity) {
      return {
        "type": "Feature",
        "properties": {
          "id": activity.activityUid,
          'activityCategory':
              'images/${Activity.solveActivityId(activity.activityCategory)}.png',
        },
        "geometry": {
          "type": "Point",
          "coordinates": [
            activity.activityLong,
            activity.activityLati,
            0.0,
          ],
        }
      };
    }).toList();

    final Map<String, dynamic> geoJson = {
      "type": "FeatureCollection",
      "crs": {
        "type": "name",
        "properties": {"name": "urn:ogc:def:crs:OGC:1.3:CRS84"}
      },
      "features": features,
    };

    await controller.addSource(
      "activities",
      GeojsonSourceProperties(
        data: geoJson,
        cluster: true,
      ),
    );

    await controller.addSymbolLayer(
      "activities",
      'activities-symbols',
      SymbolLayerProperties(
        iconImage: [
          Expressions.caseExpression,
          [
            Expressions.boolean,
            [Expressions.has, 'point_count'],
            false
          ],
          'images/circlebackground.png',
          [Expressions.get, 'activityCategory'],
        ],
        iconSize: [
          Expressions.caseExpression,
          [
            Expressions.boolean,
            [Expressions.has, 'point_count'],
            false
          ],
          0.85.r,
          0.8.r,
        ],
        iconAllowOverlap: true,
        symbolSortKey: 10.0,
      ),
    );

    await controller.addSymbolLayer(
      "activities",
      "activities-count",
      SymbolLayerProperties(
        textField: [Expressions.get, 'point_count_abbreviated'],
        textColor: '#FFFFFF',
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: [
          Expressions.step,
          [Expressions.get, 'point_count'],
          22.sp,
          5,
          24.sp,
          10,
          26.sp
        ],
      ),
    );
  }*/


  /* void _onFeatureTapped({required LatLng coordinates}) {
    double zoomLevel = controller.cameraPosition!.zoom;
    int places = getPlaces(zoomLevel);

    double roundedLatitude =
        double.parse(coordinates.latitude.toStringAsFixed(places));
    double roundedLong =
        double.parse(coordinates.longitude.toStringAsFixed(places));

    for (MiittiActivity activity in _activities) {
      double roundedActivityLatitude =
          double.parse(activity.activityLati.toStringAsFixed(places));
      double roundedActivityLong =
          double.parse(activity.activityLong.toStringAsFixed(places));

      if (roundedActivityLatitude == roundedLatitude &&
          roundedActivityLong == roundedLong) {
        if (!isAnonymous) {
          goToActivityDetailsPage(activity);
        } else {
          showSnackBar(
              context,
              'Et ole vielä viimeistellyt profiiliasi, joten\n et voi käyttää vielä sovelluksen kaikkia ominaisuuksia.',
              ConstantStyles.orange);
        }
      }
    }
  }

  _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
    controller.onFeatureTapped.add(
        (id, point, coordinates) => _onFeatureTapped(coordinates: coordinates));
  }*/

  //Commenting this to merge
}
