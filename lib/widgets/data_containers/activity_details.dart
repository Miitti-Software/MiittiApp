import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/organization.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/deep_link_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/horizontal_image_shortlist.dart';
import 'package:miitti_app/widgets/overlays/dot_indicator.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/overlays/report_bottom_sheet.dart';
import 'package:miitti_app/widgets/overlays/success_snackbar.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool isCommercialActivity = false;
  late Organization? organization;
  StreamSubscription<MiittiActivity?>? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToActivityStream();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    titleScrollController.dispose();
    descriptionScrollController.dispose();
    super.dispose();
  }

  void _subscribeToActivityStream() {
    final mapState = ref.read(mapStateProvider.notifier);
    final activityStream = ref.read(activitiesStateProvider.notifier).streamActivity(widget.activityId);

    _activitySubscription = activityStream.listen(
      (activity) async {
        if (activity != null && mounted) {
          mapState.offSetLocationVertically(inputLocation: LatLng(activity.latitude, activity.longitude));
          mapState.setZoom(15.0);

          if (activity is CommercialActivity) {
            organization = await ref.read(firestoreServiceProvider).fetchOrganization(activity.organization);
            isCommercialActivity = true;
          }
        }
      },
      onError: (e) {
        debugPrint('Error fetching activity details: $e');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userUid = ref.watch(userStateProvider.select((state) => state.uid));
    ref.read(analyticsServiceProvider).logScreenView('activity_details_screen');

    return Stack(
      children: [
        Container(color: Theme.of(context).colorScheme.surface,),
        StreamBuilder<MiittiActivity?>(
          stream: ref.read(activitiesStateProvider.notifier).streamActivity(widget.activityId),
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
            final participants = activity.participants;
            final participantsInfo = activity.participantsInfo;
            final filteredParticipantsInfo = Map<String, Map<String, dynamic>>.fromEntries(
              participantsInfo.entries
              .where((entry) => participants.contains(entry.key))
              .map((entry) => MapEntry(entry.key, entry.value)));
            final category = activity.category;
            final title = activity.title;
            final description = activity.description;
            final startTime = activity.startTime;
            final address = activity.address;
            final paid = activity.paid;
            final maxParticipants = activity.maxParticipants;
            final currentParticipants = activity.participants.length;

            Future.delayed(Duration(milliseconds: 25), () => ref.read(activitiesStateProvider.notifier).markActivityAsSeen(activity));

            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                      if (isCommercialActivity)
                        Row(
                          children: [
                            GestureDetector(
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.tertiary,
                                radius: 27,
                                child: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    organization!.image,
                                    cacheManager: ProfilePicturesCacheManager(),
                                  ),
                                  radius: 25,
                                  onBackgroundImageError: (exception, stackTrace) => const Text(
                                    '💎',
                                    style: TextStyle(fontSize: 34),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                ref.read(adsStateProvider.notifier).incrementCommercialActivityHyperlinkClickCount(activity.id);
                                final url = Uri.parse(organization!.website);
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: ScrollController(),
                                scrollDirection: Axis.horizontal,
                                child: SelectableText(
                                  organization!.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                )
                              ),
                            ),
                          ],
                        ),
                      if (isCommercialActivity) const SizedBox(height: AppSizes.verticalSeparationPadding),
                      SelectionArea(
                        child: Row(
                          children: [
                            Text(
                              isCommercialActivity ? (activity as CommercialActivity).customEmoji : config.getActivityTuple(category).item2,
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
                      child: SizedBox(  // Add this
                        width: double.infinity,  // Add this
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                GestureDetector(
                                  onTap: () {
                                    if (activity.creator == userUid) {
                                      _pickDateTime(context, activity);
                                    }
                                  },
                                  child: Row(
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
                            Expanded(  // Add this
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
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: Theme.of(context).textTheme.labelMedium,
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      context.go('/activity/${activity.id}/participants');
                                    },
                                    child: Row(
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      Row(
                        children: [
                          HorizontalImageShortlist(usersData: filteredParticipantsInfo, activityId: activity.id,),
                          const SizedBox(width: 4),
                          if (userUid == activity.creator && activity is UserCreatedActivity)
                          GestureDetector(
                            onTap: () {
                              context.push('/activity/${activity.id}/invite');
                            },
                            child: Icon(
                              Icons.add,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        ],
                      ),
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
                      Stack(
                        children: [
                          ForwardButton(
                            buttonText: config.get<String>('activity-joined-button'),
                            onPressed: () {
                              context.go('/activity/${activity.id}/chat');
                            },
                          ),
                          if (activity.latestMessage != null && activity.latestMessage!.isAfter(activity.participantsInfo[userUid]!['lastOpenedChat'] ?? DateTime(2020)))
                            DotIndicator(requestOrJoin: false),
                        ],
                      ),
                      ] else if (activity is UserCreatedActivity && activity.requests.contains(userUid)) ...[
                        const SizedBox(height: AppSizes.minVerticalPadding),
                        BackwardButton(
                          buttonText: config.get<String>('activity-requested-button'),
                          onPressed: () {
                            // Show request status
                            ErrorSnackbar.show(context, config.get<String>('invalid-activity-requested'));
                          },
                        ),
                        ] else if (activity is UserCreatedActivity && activity.requiresRequest && !activity.participants.contains(userUid)) ...[
                        ForwardButton(
                          buttonText: config.get<String>('activity-ask-to-join-button'),
                          onPressed: () async {
                            if (ref.read(userStateProvider).isAnonymous) {
                              ErrorSnackbar.show(context, config.get<String>('invalid-activity-join-anonymous'));
                              context.go('/login/welcome');
                              return;
                            }
                            // Request to join activity
                            final success = await ref.read(activitiesStateProvider.notifier).requestToJoinActivity(activity);
                            if (!mounted) return;
                            if (success) {
                              SuccessSnackbar.show(context, config.get<String>('activity-request-success'));
                            } else {
                              ErrorSnackbar.show(context, config.get<String>('activity-request-error'));
                            }
                          },
                        ),
                      ] else if (activity is UserCreatedActivity && !activity.requiresRequest && !activity.participants.contains(userUid)) ...[
                        ForwardButton(
                          buttonText: config.get<String>('activity-join-button'),
                          onPressed: () {
                            // Join activity
                            ref.read(activitiesStateProvider.notifier).joinActivity(activity);
                            SuccessSnackbar.show(context, config.get<String>('activity-join-success'));
                          },
                        ),
                      ] else if (isCommercialActivity) ...[
                        ForwardButton(
                          buttonText: config.get<String>('commercial-activity-join-button'),
                          onPressed: () async {
                            ref.read(activitiesStateProvider.notifier).joinActivity(activity);
                            SuccessSnackbar.show(context, config.get<String>('activity-join-success'));
                          },
                        ),
                      ],
                      if (isCommercialActivity) ...[
                        const SizedBox(height: AppSizes.minVerticalPadding),
                        BackwardButton(
                          buttonText: config.get<String>('commercial-activity-hyperlink-button'),
                          onPressed: () async {
                            ref.read(adsStateProvider.notifier).incrementCommercialActivityHyperlinkClickCount(activity.id);
                            final url = Uri.parse((activity as CommercialActivity).hyperlink);
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                      if (activity.creator == userUid && (activity is UserCreatedActivity && activity.requests.isNotEmpty)) ...[
                        const SizedBox(height: AppSizes.minVerticalPadding),
                        Stack(
                          children: [
                            BackwardButton(
                              buttonText: config.get<String>('activity-requests-button'),
                              onPressed: () {
                                context.go('/activity/${activity.id}/requests');
                              },
                            ),
                            DotIndicator(requestOrJoin: true),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      if (activity.creator == userUid) ...[
                        TextButton(
                          onPressed:() {
                            ref.read(activitiesStateProvider.notifier).archiveActivity(activity);
                            context.pop();
                          },
                          child: Text(
                            config.get<String>('archive-activity-button'),
                          ),
                        ),
                      ],
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
                          } else if (activity.participants.contains(userUid) || (activity is UserCreatedActivity && activity.requests.contains(userUid))) {
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
                              : (activity.participants.contains(userUid) || (activity is UserCreatedActivity && activity.requests.contains(userUid)))
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
        ),
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context, MiittiActivity activity) async {
    final language = ref.watch(languageProvider);

    // Show the date picker first
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      locale: Locale(language.code),
      initialDate: activity.startTime ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            textTheme: const TextTheme().copyWith(
              titleSmall: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w300,
                fontSize: 16,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Show the time picker after a date has been picked
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(activity.startTime ?? DateTime.now()),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              textTheme: const TextTheme().copyWith(
                titleSmall: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Combine the picked date and time into a single DateTime object
        activity.updateStartTime(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
        ref.read(firestoreServiceProvider).updateActivityTransaction(activity.toMap(), activity.id, activity is CommercialActivity);
      } else {
        // If the user cancels the time picker, reset the date
        activity.updateStartTime(null);
        ref.read(firestoreServiceProvider).updateActivityTransaction(activity.toMap(), activity.id, activity is CommercialActivity);
      }
    } else {
      // If the user cancels the date picker, reset the date
      activity.updateStartTime(null);
      ref.read(firestoreServiceProvider).updateActivityTransaction(activity.toMap(), activity.id, activity is CommercialActivity);
    }
  }
}