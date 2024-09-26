import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';

class ActivityListTile extends ConsumerWidget {
  final MiittiActivity activity;

  const ActivityListTile(this.activity, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);

    final title = activity.title;
    final startTime = activity.startTime;
    final address = activity.address;
    final paid = activity.paid;
    final maxParticipants = activity.maxParticipants;
    final currentParticipants = activity.participants.length;

    // Fetch user data and seen activities
    final currentUser = ref.read(userStateProvider).data;
    final seenActivities = ref.watch(activitiesStateProvider).seenActivities;

    // Check if the user is a participant
    final isParticipant = activity.participants.contains(currentUser.uid);

    final condition = seenActivities.any((tuple) => tuple.item1.id == activity.id && tuple.item2.isAfter(activity.latestActivity));

    // Check if the latest activity is more recent than the last seen datetime
    final lastSeen = activity.participantsInfo[currentUser.uid]?['lastSeen'];
    final hasNewActivity = isParticipant && (lastSeen == null && !condition || lastSeen != null && (activity.latestActivity.isAfter(lastSeen)) && !condition);
        

    return InkWell(
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
        ref.read(mapStateProvider.notifier).setToggleIndex(0);
      },
      child: Card(
        color: Theme.of(context).colorScheme.surface.withAlpha(200),
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Stack(
                  children: [
                    activity is UserCreatedActivity ? ActivityMarker(activity: activity) : CommercialActivityMarker(activity: activity),
                    if (hasNewActivity)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                         fontSize: 18,
                         fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.normal,
                        ),
                        softWrap: true,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    startTime != null
                                        ? DateFormat(
                                                'dd.MM.yyyy \'${config.get<String>('activity-text-between-date-and-time')}\' HH.mm')
                                            .format(activity.startTime!.toLocal())
                                        : config.get<String>('activity-missing-start-time'),
                                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.minVerticalPadding),
                              Row(
                                children: [
                                  Icon(
                                    paid ? Icons.attach_money_rounded : Icons.money_off_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    paid ? config.get<String>('activity-paid') : config.get<String>('activity-free'),
                                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                      overflow: TextOverflow.ellipsis,
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
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      address,
                                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$currentParticipants / $maxParticipants',
                                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
