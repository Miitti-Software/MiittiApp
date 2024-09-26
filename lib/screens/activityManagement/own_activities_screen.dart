import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/widgets/data_containers/activity_list_tile.dart';
import 'package:miitti_app/widgets/data_containers/infinite_list.dart';

class OwnActivitiesScreen extends ConsumerStatefulWidget {
  const OwnActivitiesScreen({super.key});

  @override
  _OwnActivitiesScreenState createState() => _OwnActivitiesScreenState();
}

class _OwnActivitiesScreenState extends ConsumerState<OwnActivitiesScreen> {
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
    final activities = ref.watch(activitiesStateProvider).userActivities;

    return ref.read(userStateProvider).isAnonymous
        ? const AnonymousUserScreen()
        : Scaffold(
            // appBar: AppBar(
            //   title: Text(config.get<String>('own-activities-screen-title')),
            //   backgroundColor: Theme.of(context).colorScheme.surface,
            //   notificationPredicate: (notification) => false,
            // ),
            body: Container(
              color: Theme.of(context).colorScheme.surface,
              child: activities.isEmpty
                  ? Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onPressed: () {
                          context.push('/create-activity/category');
                        },
                        child: Text(config.get<String>('create-activity-prompt-button')),
                      ),
                    )
                  : InfiniteList(
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