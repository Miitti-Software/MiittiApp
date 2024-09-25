import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/message.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/service_providers.dart';

final chatStateProvider = StateNotifierProvider.family<ChatState, List<Message>, MiittiActivity>((ref, activity) {
  return ChatState(ref, activity);
});

class ChatState extends StateNotifier<List<Message>> {
  final MiittiActivity _activity;
  final Ref ref;
  late StreamSubscription _subscription;

  ChatState(this.ref, this._activity) : super([]) {
    _fetchMessages(_activity is CommercialActivity);
  }

  void _fetchMessages(isCommercialActivity) {
    _subscription = ref.read(firestoreServiceProvider).getMessages(_activity.id, isCommercialActivity: isCommercialActivity).listen((snapshot) {
      final messages = snapshot.docs.map((doc) => Message.fromFirestore(doc.data() as Map<String, dynamic>)).toList();
      state = messages;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> sendMessage(Message message, isCommercialActivity) async {
    await ref.read(firestoreServiceProvider).sendMessage(_activity.id, message, isCommercialActivity: isCommercialActivity);
  }
}