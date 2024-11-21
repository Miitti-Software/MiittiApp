import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/screens/peopleManagement/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/users_state.dart';

class RequestsList extends ConsumerStatefulWidget {
  const RequestsList({super.key});

  @override
  _RequestsListState createState() => _RequestsListState();
}

class _RequestsListState extends ConsumerState<RequestsList> {
  final ScrollController _scrollController = ScrollController();
  double previousMaxScrollPosition = 0.0;
  late Future<MiittiActivity?> activityFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activityId = GoRouterState.of(context).pathParameters['id']!;
    activityFuture = fetchActivityDetails(activityId);
  }

  Future<MiittiActivity?> fetchActivityDetails(String activityId) async {
    return await ref.read(activitiesStateProvider.notifier).fetchActivity(activityId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);

    return ref.read(userStateProvider).isAnonymous
        ? const AnonymousUserScreen()
        : FutureBuilder<MiittiActivity?>(
            future: activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).colorScheme.onPrimary,
                          thickness: 2.0,
                          indent: 100,
                          endIndent: 100,
                        ),
                        const Spacer(),
                        Text('Error fetching activity data', style: Theme.of(context).textTheme.bodyMedium),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).colorScheme.onPrimary,
                          thickness: 2.0,
                          indent: 100,
                          endIndent: 100,
                        ),
                        const Spacer(),
                        Text('Activity not found', style: Theme.of(context).textTheme.bodyMedium),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              }

              final activity = snapshot.data! as UserCreatedActivity;
              final requestsIds = activity.requests;

              return Scaffold(
                appBar: AppBar(
                  title: Text(config.get<String>('activity-requests-list-title')),
                ),
                body: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.only(top: AppSizes.minVerticalEdgePadding),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: requestsIds.length,
                    itemBuilder: (BuildContext context, int index) {
                      final userId = requestsIds[index];
                      return FutureBuilder<MiittiUser?>(
                        future: ref.read(usersStateProvider.notifier).fetchUser(userId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                            );
                          } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                            return const ListTile(
                              title: Text('Error loading user'),
                            );
                          }

                          final user = userSnapshot.data!;
                          return CustomRequestListTile(
                            uid: userId,
                            name: user.name,
                            profilePicture: user.profilePicture,
                            onAccept: () async {
                              await ref.read(activitiesStateProvider.notifier).acceptRequest(GoRouterState.of(context).pathParameters['id']!, user);
                              setState(() {
                                activity.requests.remove(userId);
                              });
                            },
                            onDecline: () async {
                              await ref.read(activitiesStateProvider.notifier).declineRequest(GoRouterState.of(context).pathParameters['id']!, userId);
                              setState(() {
                                activity.requests.remove(userId);
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
  }
}

class CustomRequestListTile extends StatelessWidget {
  final String uid;
  final String name;
  final String profilePicture;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const CustomRequestListTile({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/people/user/$uid'),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profilePicture),
        ),
        title: Text(name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}