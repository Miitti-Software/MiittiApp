import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/widgets/data_containers/activity_list_tile.dart';
import 'package:miitti_app/widgets/data_containers/infinite_list.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load initial activities
    ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final activities = ref.watch(activitiesStateProvider).participatingActivities;

    return ref.read(userStateProvider).isAnonymous
        ? const AnonymousUserScreen()
        : Scaffold(
            // appBar: AppBar(
            //   title: Text(config.get<String>('chats-screen-title')),
            //   backgroundColor: Theme.of(context).colorScheme.surface,
            //   notificationPredicate: (notification) => false,
            // ),
            body: Container(
              color: Theme.of(context).colorScheme.surface,
              child: InfiniteList(
                dataSource: activities,
                refreshFunction: () => ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities(fullRefresh: true),
                listTileBuilder: (BuildContext context, int index) {
                  return ActivityListTile(
                    activities[index],
                  );
                },
                scrollController: _scrollController,
                loadMoreFunction: () => ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities(),
              ),
            ),
          );
  }
}