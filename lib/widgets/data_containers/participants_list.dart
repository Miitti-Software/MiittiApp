import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/models/miitti_activity.dart';

class ParticipantsList extends ConsumerStatefulWidget {
  final String activityId;

  const ParticipantsList({super.key, required this.activityId});

  @override
  _ParticipantsListState createState() => _ParticipantsListState();
}

class _ParticipantsListState extends ConsumerState<ParticipantsList> {
  final ScrollController _scrollController = ScrollController();
  double previousMaxScrollPosition = 0.0;
  late Future<MiittiActivity?> activityFuture;

  @override
  void initState() {
    super.initState();
    activityFuture = fetchActivityDetails(widget.activityId);
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

              final activity = snapshot.data!;
              final participantsIds = activity.participantsInfo.keys.toList();
              final participantsInfo = activity.participantsInfo;

              return Scaffold(
                appBar: AppBar(
                  title: Text(config.get<String>('activity-participants-list-title')),
                ),
                body: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.only(top: AppSizes.minVerticalEdgePadding),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: participantsIds.length,
                    itemBuilder: (BuildContext context, int index) {
                      final userId = participantsIds[index];
                      final user = participantsInfo[userId];
                      return CustomUserListTile(
                        uid: userId,
                        name: user!['name'],
                        profilePicture: user['profilePicture'],
                        onTap: () async {
                          await ref.read(usersStateProvider.notifier).fetchUser(userId);
                          context.go('/people/user/$userId');
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

class CustomUserListTile extends StatelessWidget {
  final String uid;
  final String name;
  final String profilePicture;
  final VoidCallback onTap;

  const CustomUserListTile({
    super.key,
    required this.uid,
    required this.name,
    required this.profilePicture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profilePicture),
      ),
      title: Text(name),
      onTap: onTap,
    );
  }
}