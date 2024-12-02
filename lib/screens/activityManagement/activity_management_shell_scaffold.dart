import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/buttons/navigation_choice_button.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';

class ActivityManagementShellScaffold extends ConsumerWidget {
  const ActivityManagementShellScaffold({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('NavigationShellScaffold'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(BuildContext context, WidgetRef ref, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(notificationServiceProvider).setNotificationsEnabled(true);
    final config = ref.watch(remoteConfigServiceProvider);
    // final titles = [
    //   config.get<String>('chats-screen-title'),
    //   config.get<String>('own-activities-screen-title'),
    //   config.get<String>('others-activities-screen-title'),
    // ];
    // final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.get<String>('activity-management-screen-title')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        notificationPredicate: (notification) => false,
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: AppSizes.minVerticalPadding),
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildBranchButton(context, ref, 0, config.get<String>('chats-screen-title')),
                    const SizedBox(width: 4),
                    _buildBranchButton(context, ref, 1, config.get<String>('own-activities-screen-title')),
                    const SizedBox(width: 4),
                    _buildBranchButton(context, ref, 2, config.get<String>('others-activities-screen-title')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
    );
  }

  Widget _buildBranchButton(BuildContext context, WidgetRef ref, int index, String title) {
    final isSelected = navigationShell.currentIndex == index;

    return NavigationChoiceButton(
      text: title,
      isSelected: isSelected,
      onSelected: (selected) {
        if (ref.read(userStateProvider).isAnonymous && [0, 2].contains(index)) {
          BottomSheetDialog.show(
            context: context,
            title: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-title'),
            body: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-text'),
            confirmText: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-action-prompt'),
            onConfirmPressed: () {
              context.pop();
              context.push('/login/complete-profile/name');
            },
            cancelText: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-cancel'),
            onCancelPressed: () => context.pop(),
            disclaimer: ref.read(remoteConfigServiceProvider).get<String>('anonymous-dialog-disclaimer'),
          );
          if (index != 2) {
            _goBranch(context, ref, index);
          } else {
            return;
          }
        } else {
          if (index == 3 && ref.read(usersStateProvider).users.length < 10) {
            ref.read(usersStateProvider.notifier).loadMoreUsers();
          }
          _goBranch(context, ref, index);
        }
      },
    );
  }
}