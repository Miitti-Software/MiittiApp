import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/message.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/chat_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/data_containers/activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/commercial_activity_marker.dart';
import 'package:miitti_app/widgets/data_containers/infinite_list.dart';
import 'dart:ui' as ui;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Stream<MiittiActivity?> activityStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activityId = GoRouterState.of(context).pathParameters['id']!;
    activityStream = fetchActivityDetails(activityId);
  }

  Stream<MiittiActivity?> fetchActivityDetails(String activityId) async* {
    final activitiesState = ref.read(activitiesStateProvider);

    // Check if the activity is already in the state
    MiittiActivity? activity = activitiesState.activities.firstWhereOrNull((a) => a.id == activityId);
    activity ??= await ref.read(activitiesStateProvider.notifier).fetchActivity(activityId);
    yield activity;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MiittiActivity?>(
      stream: activityStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading activity details'),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Activity not found'),
          );
        }

        final activity = snapshot.data!;
        final isCommercialActivity = activity is CommercialActivity;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppBar(
                  title: Text(activity.title, style: Theme.of(context).textTheme.titleMedium),
                  notificationPredicate: (notification) => false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new), 
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          context.go('/activity/${activity.id}');
                        },
                        child: isCommercialActivity ? Row(children: [CommercialActivityMarker(activity: activity, size: 24), const SizedBox(width: 8)]) : ActivityMarker(activity: activity, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final messages = ref.watch(chatStateProvider(activity));
                    return InfiniteList<Message>(
                      dataSource: messages,
                      listTileBuilder: (context, index) {
                        final message = messages[index];
                        final currentUserUid = ref.read(userStateProvider).uid;
                        final isCurrentUser = message.senderId == currentUserUid;
                        final participantInfo = activity.participantsInfo[message.senderId];

                        // Mark the latest message as read only if it has not been read yet
                        // TODO: Move to a method in ChatState
                        if (messages.first.senderId != currentUserUid && activity.participantsInfo[currentUserUid]!['lastReadMessage'] != messages.first.id) {
                          Map<String, dynamic> updatedFields = activity.markMessageRead(currentUserUid!, messages.first.id!).toMap();
                          Map<String, dynamic> fieldsToUpdate = {
                            'participantsInfo.$currentUserUid.lastReadMessage': updatedFields['participantsInfo'][currentUserUid]['lastReadMessage'],
                            'participantsInfo.$currentUserUid.lastOpenedChat': DateTime.now(),
                            'participantsInfo.$currentUserUid.lastSeen': DateTime.now(),
                          };
                          ref.read(firestoreServiceProvider).updateActivityFields(fieldsToUpdate, activity.id, activity is CommercialActivity);
                        }

                        final messageReadByEveryone = isReadByEveryone(message, activity.participantsInfo);

                        return CustomMessageTile(
                          message: message,
                          senderId: message.senderId,
                          isCurrentUser: isCurrentUser,
                          participantInfo: participantInfo!,
                          isReadByEveryone: messageReadByEveryone,
                        );
                      },
                      startFromBottom: true,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        minLines: 1,
                        maxLines: 5,
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: ref.watch(remoteConfigServiceProvider).get<String>('input-chat-message-placeholder'),
                          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(125)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).colorScheme.onPrimary,
                            onPressed: () {
                              final userState = ref.read(userStateProvider);
                              if (_messageController.text.isNotEmpty) {
                                final newMessage = Message(
                                  message: _messageController.text,
                                  senderId: userState.uid!,
                                  senderName: userState.data.name!,
                                  timestamp: DateTime.now(),
                                );
                                // Add the new message to the activity
                                ref.read(chatStateProvider(activity).notifier).sendMessage(newMessage, isCommercialActivity);
                                _messageController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
            ],
          ),
        );
      },
    );
  }

  // TODO: Fix this method to work in all cases
  bool isReadByEveryone(Message message, Map<String, dynamic> participantsInfo) {
    return participantsInfo.values.every((info) {
      final lastOpenedChat = info['lastOpenedChat'];
      return lastOpenedChat != null && lastOpenedChat.isAfter(message.timestamp);
    });
  }
}

class CustomMessageTile extends StatelessWidget {
  final Message message;
  final String senderId;
  final bool isCurrentUser;
  final Map<String, dynamic> participantInfo;
  final bool isReadByEveryone;

  const CustomMessageTile({
    super.key,
    required this.message,
    required this.senderId,
    required this.isCurrentUser,
    required this.participantInfo,
    required this.isReadByEveryone,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isCurrentUser) _buildProfilePicture(context),
            Flexible(child: _buildMessageBubble(context)),
            if (isCurrentUser) _buildProfilePicture(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            participantInfo['profilePicture'].replaceAll('profilePicture', 'thumb_profilePicture'),
            cacheManager: ProfilePicturesCacheManager(),
          ),
          radius: 18,
        ),
        onTap: () => context.push('/people/user/$senderId'),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    final TextStyle timestampStyle = TextStyle(
      color: isCurrentUser ? Theme.of(context).colorScheme.onPrimary.withAlpha(150) : Theme.of(context).colorScheme.onSurface.withAlpha(150),
      fontSize: 10,
    );

    final double timestampWidth = getTextWidth(_formatTimestamp(message.timestamp), timestampStyle) + 16; // Add some padding
    const double iconWidth = 16; // Icon size + padding

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7, // Set maximum width to 70% of screen width
          minWidth: timestampWidth + iconWidth + 28, // Ensure minimum width to accommodate timestamp and icon
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isCurrentUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withAlpha(25),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12.0),
              topRight: const Radius.circular(12.0),
              bottomLeft: isCurrentUser ? const Radius.circular(12.0) : const Radius.circular(2),
              bottomRight: isCurrentUser ? const Radius.circular(2) : const Radius.circular(12.0),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0), // Add padding to avoid overlap with message details
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(color: isCurrentUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: isCurrentUser ? 0 : null,
                left: isCurrentUser ? null : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: timestampStyle,
                    ),
                    const SizedBox(width: 4.0),
                    Icon(
                      isReadByEveryone ? Icons.done_all : Icons.check,
                      size: 14,
                      color: isCurrentUser ? Theme.of(context).colorScheme.onPrimary.withAlpha(150) : Theme.of(context).colorScheme.onSurface.withAlpha(150),
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

  double getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(timestamp);
    }
  }
}