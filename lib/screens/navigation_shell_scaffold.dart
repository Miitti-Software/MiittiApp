import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/custom_navigation_bar.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';

class NavigationShellScaffold extends ConsumerWidget {
  const NavigationShellScaffold({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('NavigationShellScaffold'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(BuildContext context, WidgetRef ref, int index) {
    if (index == 1) {
      ref.read(mapStateProvider.notifier).setToggleIndex(0);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: CustomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              if (ref.watch(userStateProvider).isAnonymous && [0, 2, 3].contains(index)) {
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
              } else if (ref.watch(userStateProvider).isAnonymous && index == 4) {
                context.push('/profile/settings');
              } else {
                if (index == 3 && ref.watch(usersStateProvider).users.length < 10) {
                  ref.read(usersStateProvider.notifier).loadMoreUsers();
                }
                _goBranch(context, ref, index);
              }
            },
          ),
        );
      },
    );
  }
}