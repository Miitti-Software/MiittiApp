import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/message.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';

final chatStateProvider = StateNotifierProvider.family<ChatState, List<Message>, MiittiActivity>((ref, MiittiActivity activity) {
  return ChatState(ref, activity);
});

class ChatState extends StateNotifier<List<Message>> {
  final MiittiActivity _activity;
  final Ref ref;
  late StreamSubscription _subscription;

  ChatState(this.ref, this._activity) : super([]) {
    _fetchMessages(_activity is CommercialActivity);
  }

  void _fetchMessages(isCommercialActivity) async {
    _subscription = ref.read(firestoreServiceProvider).getMessages(_activity.id, isCommercialActivity: isCommercialActivity).listen((snapshot) async {
      final messages = snapshot.docs.map((doc) => Message.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
      state = messages;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> sendMessage(Message message, isCommercialActivity) async {
    try {
      // Optimistically update the state with the new message
      state = [...state, message];

      final activity = await ref.read(activitiesStateProvider.notifier).fetchActivity(_activity.id);
      final messageId = await ref.read(firestoreServiceProvider).sendMessage(_activity.id, message, isCommercialActivity: isCommercialActivity);
      if (activity != null) {
        await ref.read(firestoreServiceProvider).updateActivityTransaction(
          activity.addMessageNotification().markMessageRead(ref.read(userStateProvider).data.uid!, messageId!).toMap(),
          activity.id,
          activity is CommercialActivity,
        );
      }

      final receivers = _activity.participants.where((participant) => participant != ref.read(userStateProvider).data.uid).toList();
      for (final participant in receivers) {
        final receiver = await ref.read(usersStateProvider.notifier).fetchUser(participant);
        if (receiver != null) {
          await ref.read(notificationServiceProvider).sendMessageNotification(
            receiver.fcmToken,
            message.message,
            _activity,
            ref.read(userStateProvider).data.name!,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      // Revert the state if sending the message fails
      state = state.where((msg) => msg != message).toList();
    }
  }
}