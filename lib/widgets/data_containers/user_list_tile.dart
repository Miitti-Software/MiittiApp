import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/service_providers.dart';

class UserListTile extends ConsumerWidget {
  final MiittiUser user;
  final VoidCallback onTap;
  final VoidCallback? onTrailingTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
    this.onTrailingTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final now = DateTime.now();
    final lastActive = user.lastActive;
    final difference = now.difference(lastActive).inMinutes;

    String status;
    Color borderColor;
    if (user.online) {
      status = config.get<String>('user-status-online');
      borderColor = Theme.of(context).colorScheme.primary;
    } else if (difference <= 30) {
      status = config.get<String>('user-status-active');
      borderColor = Theme.of(context).colorScheme.secondary;
    } else if (now.difference(user.registrationDate).inDays <= 7) {
      status = config.get<String>('user-status-new');
      borderColor = Theme.of(context).colorScheme.tertiary;
    } else {
      status = config.get<String>('user-status-away');
      borderColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: status != config.get<String>('user-status-away') ? Border.all(color: borderColor, width: 2) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(maxHeight: 100),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: user.profilePicture.replaceAll('profilePicture', 'thumb_profilePicture'),
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    cacheManager: ProfilePicturesCacheManager().instance,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                '${user.name}, ${calculateAge(user.birthday)}',
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.areas.join(', '),
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          user.favoriteActivities
                              .map((interest) => '${config.getActivityTuple(interest).item2} ${config.getActivityTuple(interest).item1}')
                              .join(', '),
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  GestureDetector(
                    onTap: onTrailingTap,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Center(child: trailing),
                    ),
                  ),
              ],
            ),
            if (status != config.get<String>('user-status-away'))
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

int calculateAge(DateTime birthday) {
  final now = DateTime.now();
  int age = now.year - birthday.year;
  if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
    age--;
  }
  return age;
}