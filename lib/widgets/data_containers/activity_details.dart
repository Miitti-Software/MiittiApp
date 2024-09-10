import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/horizontal_image_shortlist.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class ActivityDetails extends ConsumerStatefulWidget {
  final UserCreatedActivity activity;

  const ActivityDetails({
    super.key, 
    required this.activity,
  });

  @override
  ConsumerState<ActivityDetails> createState() =>
      _ActivityBottomSheetState();
}

class _ActivityBottomSheetState extends ConsumerState<ActivityDetails> {
  Map<String, Map<String, dynamic>> participants = {};
  String category = '';
  String title = '';
  String description = '';
  DateTime? startTime;
  String address = '';
  bool paid = false;
  int maxParticipants = 0;
  int currentParticipants = 0;

  bool linkCreated = false;

  @override
  void initState() {
    super.initState();
    participants = widget.activity.participants;
    category = widget.activity.category;
    title = widget.activity.title;
    description = widget.activity.description;
    startTime = widget.activity.startTime;
    address = widget.activity.address;
    paid = widget.activity.paid;
    maxParticipants = widget.activity.maxParticipants;
    currentParticipants = participants.length;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
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
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              SelectionArea(
                child: Row(
                  children: [
                    Text(
                      config.getActivityTuple(category).item2,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(          // TODO: Set max character count = 100
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            linkCreated = true;
                          });
                          await Clipboard.setData(ClipboardData(text: 'https://miittiappdev.web.app/activity/${widget.activity.id}'));    // TODO: Implement deep linking
                          ScaffoldMessenger.of(context).showSnackBar(                                       // TODO: Use Flutter toast?
                            const SnackBar(content: Text('Route copied to clipboard!')),
                          );
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: AnimatedRotation(
                          turns: linkCreated ? 0.5 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: CircleAvatar(
                            backgroundColor: linkCreated ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.link,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
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
                                  ? DateFormat('dd.MM.yyyy \'${config.get<String>('activity-text-between-date-and-time')}\' HH.mm').format(widget.activity.startTime!.toLocal())
                                  : config.get<String>('activity-missing-start-time'),
                              style: Theme.of(context).textTheme.labelMedium,
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
                          ],)
                        
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
              HorizontalImageShortlist(imageUrls: participants.values.map((e) => e['profilePicture'].replaceAll('profilePicture', 'thumb_profilePicture') as String).toList()),
              const SizedBox(height: AppSizes.minVerticalPadding * 1.4),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                  ),
                  child: PermanentScrollbar(
                    child: SingleChildScrollView(
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
              ),
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              ForwardButton(
                buttonText: 'Join',
                onPressed: () {}        // TODO: Implement joining
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(
                buttonText: 'Back',
                onPressed: () { context.pop(); }        // TODO: Implement going back
              ),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: Add reporting button

// TODO: What happens when creator is deleted?

// TODO: When are activities no longer shown? If endTime is in the past? endTime is by default 1 hour after startTime