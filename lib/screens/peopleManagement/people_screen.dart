import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/peopleManagement/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/data_containers/infinite_list.dart';
import 'package:miitti_app/widgets/data_containers/user_list_tile.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final ScrollController _scrollController = ScrollController();
  double previousMaxScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final people = ref.watch(usersProvider);
    final currentUserUid = ref.watch(userStateProvider).uid;

    // Exclude the current user from the people list
    final filteredPeople = people.where((user) => user.uid != currentUserUid).toList();

    return ref.read(userStateProvider).isAnonymous
        ? const AnonymousUserScreen()
        : Scaffold(
            appBar: AppBar(
              title: Text(config.get<String>('people-screen-title')),
              actions: [
                IconButton(
                  icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface),
                  iconSize: 36,
                  onPressed: () {
                    context.go('/people/filter');
                  },
                ),
              ],
            ),
            body: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.only(top: AppSizes.minVerticalEdgePadding),
              child: InfiniteList(
                dataSource: filteredPeople,
                refreshFunction: () => ref.read(usersStateProvider.notifier).loadMoreUsers(fullRefresh: true),
                listTileBuilder: (BuildContext context, int index) {
                  return UserListTile(
                    user: filteredPeople[index],
                    onTap: () {
                      context.go('/people/user/${filteredPeople[index].uid}');
                    },
                  );
                },
                scrollController: _scrollController,
                loadMoreFunction: () => ref.read(usersStateProvider.notifier).loadMoreUsers(),
              ),
            ),
          );
  }
}

