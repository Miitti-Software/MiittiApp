import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/overlays/dot_indicator.dart';

class CustomNavigationBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userStateProvider).data;
    final hasNotifications = ref.watch(activitiesStateProvider.notifier).hasNotifications(currentUser.uid!);
    final hasNewJoin = ref.watch(activitiesStateProvider.notifier).hasNewJoin(currentUser.uid!);
    final hasRequests = ref.watch(activitiesStateProvider.notifier).hasRequests(currentUser.uid!);

    return Container(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIcon(context, Icons.chat_bubble_outline, 0, hasNotifications, hasRequests || hasNewJoin),
              _buildIcon(context, Icons.map_outlined, 1),
              GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.surface,
                    size: 36,
                  ),
                ),
              ),
              _buildIcon(context, Icons.group_outlined, 3),
              _buildIcon(context, Icons.person_outline, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, int index, [bool hasNotification = false, bool requestOrJoin = false]) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Stack(
        children: [
          Icon( 
            icon,
            color: currentIndex == index ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
            size: 38,
          ),
          if (hasNotification)
            DotIndicator(requestOrJoin: requestOrJoin),
        ],
      ),
    );
  }
}

// TODO: Make it work in real time!!!