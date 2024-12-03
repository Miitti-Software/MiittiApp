import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/users_state.dart';

class MinUserData {
  final String uid;
  final String name;
  final String profilePicture;

  MinUserData({
    required this.uid,
    required this.name,
    required this.profilePicture,
  });
}

class HorizontalImageShortlist extends ConsumerWidget {
  final Map<String, Map<String, dynamic>> usersData;
  final String activityId;

  const HorizontalImageShortlist({super.key, required this.usersData, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<MinUserData> users = usersData.entries.map((entry) {
      final uid = entry.key;
      final data = entry.value;
      return MinUserData(
        uid: uid,
        name: data['name']!,
        profilePicture: data['profilePicture']!,
      );
    }).toList();

    return GestureDetector(
      onTap: () {
        context.go('/activity/$activityId/participants');
      },
      child: SizedBox(
        height: 42,
        child: users.length < 5
            ? Row(children: _buildSeparatedCircles(context, users, ref))
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 200),
                child: Stack(children: _buildOverlappingCircles(context, users)),
              ),
      ),
    );
  }

  List<Widget> _buildSeparatedCircles(BuildContext context, List<MinUserData> users, WidgetRef ref) {
    List<Widget> circles = [];
    int userCount = users.length;

    for (int i = 0; i < userCount; i++) {
      circles.add(_buildCircle(context, users[i], ref));
      if (i < userCount - 1) {
        circles.add(const SizedBox(width: 8));
      }
    }

    return circles;
  }

  Widget _buildCircle(BuildContext context, MinUserData user, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(usersStateProvider.notifier).fetchUser(user.uid);
        context.push('/people/user/${user.uid}');
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            user.profilePicture,
            cacheManager: ProfilePicturesCacheManager(),
          ),
          radius: 20,
        ),
      ),
    );
  }

  List<Widget> _buildOverlappingCircles(BuildContext context, List<MinUserData> users) {
    List<Widget> circles = [];
    int userCount = users.length;

    for (int i = 0; i < userCount && i < 4; i++) {
      circles.add(_buildPositionedCircle(context, users[i], i * 24.0));
    }

    if (userCount > 4) {
      circles.add(_buildPositionedCircle(context, users[4], 4 * 24.0));
      circles.add(_buildRemainingCircle(context, userCount - 4, 4 * 24.0));
    }

    return circles;
  }

  Widget _buildPositionedCircle(BuildContext context, MinUserData user, double leftPosition) {
    return Positioned(
      left: leftPosition,
      child: GestureDetector(
        onTap: () {
          context.go('/activity/$activityId/participants');
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              user.profilePicture,
              cacheManager: ProfilePicturesCacheManager(),
            ),
            radius: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingCircle(BuildContext context, int remainingCount, double leftPosition) {
    return Positioned(
      left: leftPosition,
      child: GestureDetector(
        onTap: () {
          context.go('/activity/$activityId/participants');
        },
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    usersData.values.elementAt(4)['profilePicture']!,
                    cacheManager: ProfilePicturesCacheManager(),
                  ),
                  radius: 20,
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                '+$remainingCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}