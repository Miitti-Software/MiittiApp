import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/create_activity_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/data_containers/commercial_spot.dart';

class ChooseActivityLocationScreen extends ConsumerStatefulWidget {
  const ChooseActivityLocationScreen({super.key});

  @override
  _ChooseActivityLocationScreenState createState() => _ChooseActivityLocationScreenState();
}

class _ChooseActivityLocationScreenState extends ConsumerState<ChooseActivityLocationScreen> {
  List<CommercialSpot> spots = [];
  late ValueNotifier<int> selectedSpotNotifier;
  LatLng location = const LatLng(60.1699, 24.9325);
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    selectedSpotNotifier = ValueNotifier<int>(-1);
    mapController = MapController();
    final userLocation = ref.read(mapStateProvider).location;
    final createActivityState = ref.read(createActivityStateProvider);
    location = createActivityState.latitude != null ? LatLng(createActivityState.latitude!, createActivityState.longitude!) : LatLng(userLocation.latitude, userLocation.longitude);
    fetchSpots();
  }

  void fetchSpots() {
    if (ref.read(createActivityStateProvider).category == null) {
      return;
    }
    ref.read(firestoreServiceProvider).fetchCommercialSpots(ref.read(createActivityStateProvider).category!).then((value) {
      setState(() {
        spots = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('create_activity_location_screen');

    return Scaffold(
      body: Center(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    config.get<String>('create-activity-location-title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        keepAlive: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        initialCenter: location,
                        initialZoom: 13.0,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            location = point;
                            mapController.move(location, 13.0); // Update the map's center
                            selectedSpotNotifier.value = -1; // Deselect any previously selected spot
                          });
                        },
                        onPositionChanged: (position, hasGesture) {
                          for (int i = 0; i < spots.length; i++) {
                            bool onSpot = (spots[i].latitude - position.center!.latitude)
                                        .abs() <
                                    0.0002 &&
                                (spots[i].longitude - position.center!.longitude).abs() <
                                    0.0002;
                            if (onSpot) {
                              selectedSpotNotifier.value = i;
                              location = position.center!;
                              return;
                            }
                          }
                          selectedSpotNotifier.value = -1;
                          location = position.center!;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://api.mapbox.com/styles/v1/miittiapp/clt1ytv8s00jz01qzfiwve3qm/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                          additionalOptions: const {
                            'accessToken': mapboxAccess,
                          },
                        ),
                        Center(
                          child: Image.asset(
                            'images/location.png',
                            height: 65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                spots.isNotEmpty
                    ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          config.get<String>('create-activity-location-recommendations'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    )
                    : const Spacer(),
                const SizedBox(height: AppSizes.minVerticalPadding),
                spots.isNotEmpty
                    ? Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: selectedSpotNotifier,
                          builder: (context, selectedSpot, kid) {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: spots.length,
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSpotNotifier.value = index;
                                      location = LatLng(
                                          spots[index].latitude, spots[index].longitude);
                                      mapController.move(location, 13.0); // Update the map's center
                                      ref.read(adsStateProvider.notifier).incrementCommercialSpotClickCount(spots[index].id);
                                    });
                                  },
                                  child: CommercialSpotWidget(
                                    spot: spots[index],
                                    highlight: index == selectedSpot,
                                  ));
                                },
                              );
                            }),
                      )
                    : Container(),
                const SizedBox(height: AppSizes.minVerticalPadding),
                LinearProgressIndicator(
                  value: 0.5, // 50% progress
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                const SizedBox(height: AppSizes.minVerticalPadding),
                ForwardButton(
                  buttonText: config.get<String>('forward-button'),
                  onPressed: () {
                    ref.read(createActivityStateProvider.notifier).update((state) =>
                                  state.copyWith(latitude: location.latitude, longitude: location.longitude));
                    context.go('/create-activity/details');
                  },
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                BackwardButton(
                  buttonText: config.get<String>('back-button'),
                  onPressed: () => context.go('/create-activity/category'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}