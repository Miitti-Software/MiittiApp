import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/message.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/chat_state.dart';
import 'package:miitti_app/state/user.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ChatScreen(this.activityId, {super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<MiittiActivity?> fetchActivityDetails(String activityId) async {
    final activitiesState = ref.read(activitiesStateProvider);

    // Check if the activity is already in the state
    MiittiActivity? activity = activitiesState.activities.firstWhereOrNull((a) => a.id == activityId);
    activity ??= await ref.read(activitiesStateProvider.notifier).fetchActivity(activityId);
    return activity;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MiittiActivity?>(
      future: fetchActivityDetails(widget.activityId),
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
        final messages = ref.watch(chatStateProvider(activity));
        final isCommercialActivity = activity is CommercialActivity;

        return Scaffold(
          appBar: AppBar(
            title: Text(activity.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.senderName),
                      subtitle: Text(message.message),
                      trailing: Text(DateFormat('HH:mm').format(message.timestamp)),
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
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}