import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/create_activity_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/data_containers/infinite_list.dart';
import 'package:miitti_app/widgets/data_containers/user_list_tile.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelection(MiittiUser user) {
    final createActivityState = ref.read(createActivityStateProvider.notifier);
    setState(() {
      if (createActivityState.invitedUsers.contains(user)) {
        createActivityState.invitedUsers.remove(user);
      } else {
        createActivityState.invitedUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final people = ref.watch(usersProvider);
    final invitedUsers = ref.watch(createActivityStateProvider.notifier).invitedUsers;
    final currentUserUid = ref.watch(userStateProvider).uid;

    // Exclude the current user from the people list
    final filteredPeople = people.where((user) => user.uid != currentUserUid).toList();

    return Scaffold(
      body: Center(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(4.0),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      config.get<String>('invite-screen-title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                Expanded(
                  child: InfiniteList(
                    dataSource: filteredPeople,
                    refreshFunction: () => ref.read(usersStateProvider.notifier).loadMoreUsers(fullRefresh: true),
                    listTileBuilder: (BuildContext context, int index) {
                      final user = filteredPeople[index];
                      final isSelected = invitedUsers.contains(user);

                      return UserListTile(
                        user: user,
                        onTap: () => _toggleSelection(user),
                        onTrailingTap: () => _toggleSelection(user),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                      );
                    },
                    scrollController: _scrollController,
                    loadMoreFunction: () => ref.read(usersStateProvider.notifier).loadMoreUsers(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      ForwardButton(
                        buttonText: config.get<String>('invite-screen-send-button'),
                        onPressed: () async {
                          for (final invitee in invitedUsers) {
                            ref.read(notificationServiceProvider).sendInviteNotification(
                              ref.read(userStateProvider).data.toMiittiUser(),
                              invitee,
                              await ref.read(activitiesStateProvider.notifier).fetchActivity(GoRouterState.of(context).pathParameters['id']!) as UserCreatedActivity);
                          }
                          context.pop();
                        },
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding),
                      BackwardButton(
                        buttonText: config.get<String>('back-button'),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(height: AppSizes.minVerticalPadding + 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}