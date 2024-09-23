import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/widgets/buttons/deep_link_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/horizontal_image_shortlist.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/overlays/report_bottom_sheet.dart';
import 'package:miitti_app/widgets/overlays/success_snackbar.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class ActivityDetails extends ConsumerStatefulWidget {
  final String activityId;

  const ActivityDetails({
    super.key,
    required this.activityId,
  });

  @override
  ConsumerState<ActivityDetails> createState() => _ActivityDetailsState();
}

class _ActivityDetailsState extends ConsumerState<ActivityDetails> {
  final ScrollController titleScrollController = ScrollController();
  final ScrollController descriptionScrollController = ScrollController();

  @override
  void dispose() {
    titleScrollController.dispose();
    descriptionScrollController.dispose();
    super.dispose();
  }

  Future<MiittiActivity?> fetchActivityDetails(String activityId) async {
    final activitiesState = ref.read(activitiesStateProvider);
    final mapState = ref.read(mapStateProvider.notifier);

    // Check if the activity is already in the state
    final existingActivity = activitiesState.activities.firstWhereOrNull(
      (activity) => activity.id == activityId,
    );

    if (existingActivity != null) {
      Future(() {
        mapState.offSetLocationVertically(inputLocation: LatLng(existingActivity.latitude, existingActivity.longitude));
        mapState.setZoom(15.0);
      });
      return existingActivity;
    }

    // Fetch from Firestore if not found in state
    final activity = await ref.read(activitiesStateProvider.notifier).fetchActivity(activityId);
    if (activity != null) {
      mapState.offSetLocationVertically(inputLocation: LatLng(activity.latitude, activity.longitude));
      mapState.setZoom(15.0);
    }
    return activity;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userUid = ref.watch(userStateProvider.select((state) => state.uid));

    return FutureBuilder<MiittiActivity?>(
      future: fetchActivityDetails(widget.activityId),
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
        final participantsInfo = activity.participantsInfo;
        final category = activity.category;
        final title = activity.title;
        final description = activity.description;
        final startTime = activity.startTime;
        final address = activity.address;
        final paid = activity.paid;
        final maxParticipants = activity.maxParticipants;
        final currentParticipants = activity.participants.length;

        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width - AppSizes.fullContentWidth) / 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    color: Theme.of(context).colorScheme.onPrimary,
                    thickness: 2.0,
                    indent: 100,
                    endIndent: 100,
                  ),
                  const SizedBox(height: AppSizes.verticalSeparationPadding),
                  SelectionArea(
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
                                controller: titleScrollController,
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  softWrap: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Align(
                          alignment: Alignment.topRight,
                          child: DeepLinkButton(route: 'https://miitti-app.web.app/activity/${activity.id}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectionArea(
                    child: Row(
                      children: [
                        Column(
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
                                      ? DateFormat('dd.MM.yyyy \'${config.get<String>('activity-text-between-date-and-time')}\' HH.mm').format(activity.startTime!.toLocal())
                                      : config.get<String>('activity-missing-start-time'),
                                  style: Theme.of(context).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.minVerticalPadding),
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
                        const SizedBox(width: 20),
                        SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    address,
                                    style: Theme.of(context).textTheme.labelMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$currentParticipants / $maxParticipants',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.minVerticalPadding),
                  HorizontalImageShortlist(imageUrls: participantsInfo.values.map((e) => e['profilePicture'].replaceAll('profilePicture', 'thumb_profilePicture') as String).toList()),
                  const SizedBox(height: AppSizes.minVerticalPadding * 1.4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 120,
                      maxHeight: 150,
                    ),
                    child: PermanentScrollbar(
                      controller: descriptionScrollController,
                      child: SingleChildScrollView(
                        controller: descriptionScrollController,
                        padding: const EdgeInsets.only(right: 8),
                        child: SelectionArea(
                          child: Text(
                            description,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.verticalSeparationPadding),
                  if (activity.creator == userUid || activity.participants.contains(userUid)) ...[
                  ForwardButton(
                    buttonText: config.get<String>('activity-joined-button'),
                    onPressed: () {
                      // TODO: Open activity chat
                    },
                  ),
                  ] else if (activity is UserCreatedActivity && activity.requiresRequest && !activity.participants.contains(userUid)) ...[
                    ForwardButton(
                      buttonText: config.get<String>('activity-ask-to-join-button'),
                      onPressed: () {
                        // TODO: Implement request to join functionality and refactor & test push notification service
                      },
                    ),
                  ] else if (activity is UserCreatedActivity && !activity.requiresRequest && !activity.participants.contains(userUid)) ...[
                    ForwardButton(
                      buttonText: config.get<String>('activity-join-button'),
                      onPressed: () {
                        // TODO: Send notification to creator
                        ref.read(activitiesStateProvider.notifier).joinActivity(activity);
                        ref.read(notificationServiceProvider).sendJoinNotification(activity);
                        ref.read(userStateProvider).data.incrementActivitiesJoined();
                        SuccessSnackbar.show(context, config.get<String>('activity-join-success'));
                        setState(() {
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: AppSizes.minVerticalPadding),
                  TextButton(
                    onPressed: () {
                      if (activity.creator == userUid) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: Text(config.get<String>('delete-activity-confirm-title')),
                              content: Text(config.get<String>('delete-activity-confirm-text')),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: Text(config.get<String>('cancel-button')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(activitiesStateProvider.notifier).deleteActivity(activity);
                                    SuccessSnackbar.show(context, config.get<String>('activity-delete-success'));
                                    context.pop();
                                    context.pop();
                                  },
                                  child: Text(config.get<String>('delete-button')),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (activity.participants.contains(userUid)) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: Text(config.get<String>('leave-activity-confirm-title')),
                              content: Text(config.get<String>('leave-activity-confirm-text')),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: Text(config.get<String>('cancel-button')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(activitiesStateProvider.notifier).leaveActivity(activity);
                                    ref.read(userStateProvider).data.decrementActivitiesJoined();
                                    ErrorSnackbar.show(context, config.get<String>('leave-activity-success'));
                                    setState(() {
                                    });
                                    context.pop();
                                  },
                                  child: Text(config.get<String>('leave-activity-button')),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        ReportBottomSheet.show(
                          context: context,
                          isActivity: true,
                          id: widget.activityId,
                        );
                      }
                    },
                    child: Text(
                      activity.creator == userUid
                          ? config.get<String>('delete-activity-button')
                          : activity.participants.contains(userUid)
                              ? config.get<String>('leave-activity-button')
                              : config.get<String>('report-activity-button'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.minVerticalPadding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}