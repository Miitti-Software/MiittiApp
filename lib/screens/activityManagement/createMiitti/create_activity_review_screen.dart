import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/screens/map_screen.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/create_activity_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/overlays/success_snackbar.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class CreateActivityReviewScreen extends ConsumerStatefulWidget {
  const CreateActivityReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateActivityReviewScreen> createState() => _CreateActivityReviewScreenState();
}

class _CreateActivityReviewScreenState extends ConsumerState<CreateActivityReviewScreen> {
  final ScrollController titleScrollController = ScrollController();
  final ScrollController descriptionScrollController = ScrollController();

  @override
  void dispose() {
    titleScrollController.dispose();
    descriptionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createActivityState = ref.watch(createActivityStateProvider);
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('create_activity_review_screen');
    final mapController = MapController();

    return FutureBuilder<UserCreatedActivity>(
      future: ref.read(createActivityStateProvider.notifier).createUserCreatedActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Divider(
                    color: Theme.of(context).colorScheme.onPrimary,
                    thickness: 2.0,
                    indent: 100,
                    endIndent: 100,
                  ),
                  const Spacer(),
                  Text(config.get<String>('activity-fetch-error'), style: Theme.of(context).textTheme.bodyMedium),
                  IconButton(
                    onPressed: () => context.go('/'), 
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              )
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Divider(
                    color: Theme.of(context).colorScheme.onPrimary,
                    thickness: 2.0,
                    indent: 100,
                    endIndent: 100,
                  ),
                  const Spacer(),
                  Text(config.get<String>('activity-fetch-missing-data'), style: Theme.of(context).textTheme.bodyMedium),
                  IconButton(
                    onPressed: () => context.go('/'), 
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              )
            ),
          );
        }

        final activity = snapshot.data!;
        final category = activity.category;
        final title = activity.title;
        final description = activity.description;
        final startTime = activity.startTime;
        final address = activity.address;
        final paid = activity.paid;
        final maxParticipants = activity.maxParticipants;

        return Scaffold(
          body: Center(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(4.0),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            config.get<String>('create-activity-review-title'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          child: FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              keepAlive: true,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              initialCenter: LatLng(
                                activity.latitude,
                                activity.longitude,
                              ),
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // Disable all interactions
                              ),
                              minZoom: 5.0,
                              maxZoom: 18.0,
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
                              ),
                              Center(
                                child: ActivityMarker(activity: activity),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      SelectionArea(
                        child: SizedBox(
                          width: double.infinity, // Ensure the Row has bounded width
                          child: Row(
                            children: [
                              Text(
                                config.getActivityTuple(category).item2,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: Theme.of(context).textTheme.titleMedium!.fontSize! * 3.3,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Text(
                                      title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SelectionArea(
                        child: SizedBox(
                          width: double.infinity, // Ensure the Row has bounded width
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          startTime != null
                                              ? DateFormat('dd.MM.yyyy \'${config.get<String>('activity-text-between-date-and-time')}\' HH.mm').format(startTime.toLocal())
                                              : config.get<String>('activity-missing-start-time'),
                                          style: Theme.of(context).textTheme.labelMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          paid ? Icons.attach_money_rounded : Icons.money_off_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          paid ? config.get<String>('activity-paid') : config.get<String>('activity-free'),
                                          style: Theme.of(context).textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'max. $maxParticipants osallistujaa',
                                          style: Theme.of(context).textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            address,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.labelMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.verticalSeparationPadding),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 100,
                          maxHeight: 200,
                        ),
                        child: PermanentScrollbar(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: SingleChildScrollView(
                              controller: descriptionScrollController,
                              child: Text(
                                description,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      LinearProgressIndicator(
                        value: 0.99,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      ForwardButton(
                        buttonText: config.get<String>('publish-button'),
                        onPressed: () {
                          ref.read(createActivityStateProvider.notifier).publishUserCreatedActivity();
                          ref.read(mapStateProvider.notifier).setLocation(LatLng(activity.latitude, activity.longitude));
                          SuccessSnackbar.show(context, config.get<String>('create-activity-success'));
                          GoRouter.of(context).go('/create-activity/category');
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () {
                              GoRouter.of(context).go('/');
                            },
                          ).then((_) => ref.read(createActivityStateProvider.notifier).reset());
                        },
                      ),
                      const SizedBox(height: 10),
                      BackwardButton(
                        buttonText: config.get<String>('back-button'),
                        onPressed: () {
                          context.go('/create-activity/invite');
                        },
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding + 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}