import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/bottom_sheet_dialog.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

class AcceptPushNotificationsScreen extends ConsumerStatefulWidget {
  const AcceptPushNotificationsScreen({super.key});

  @override
  _AcceptPushNotificationsScreenState createState() => _AcceptPushNotificationsScreenState();
}

class _AcceptPushNotificationsScreenState extends ConsumerState<AcceptPushNotificationsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('accept_push_notifications_screen');

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('accept-push-notifications-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('accept-push-notifications-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          ChoiceButton(
            text: config.get<String>('accept-push-notifications-button'),
            onSelected: (bool selected) {
              if (!selected) {
                ref.read(notificationServiceProvider).requestPermission(true);
                setState(() {
                    notificationsEnabled = true;
                  },
                );
              }
            },
            isSelected: notificationsEnabled,
          ),
          ChoiceButton(
            text: config.get<String>('decline-push-notifications-button'),
            onSelected: (bool selected) {
              if (!selected) {
                setState(() {
                    notificationsEnabled = false;
                  },
                );
              }
            },
            isSelected: !notificationsEnabled,
          ),

          
          const Spacer(),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () {
            if (!notificationsEnabled) {
              BottomSheetDialog.show(
                context: context,
                title: config.get<String>('accept-push-notifications-dialog-title'),
                body: config.get<String>('accept-push-notifications-dialog-text'),
                confirmText: config.get<String>('accept-push-notifications-dialog-confirm'),
                cancelText: config.get<String>('accept-push-notifications-dialog-cancel'),
                onConfirmPressed: () async {
                  bool granted = await ref.read(notificationServiceProvider).requestPermission(true);
                  if (granted && context.mounted) {
                    context.pop();
                    context.push('/login/complete-profile/community-norms');
                  } else {
                    if (context.mounted) {
                      ErrorSnackbar.show(context, config.get<String>('accept-push-notifications-dialog-error'));
                      context.pop();
                    }
                  }
                },
                onCancelPressed: () {
                  context.pop();
                  context.push('/login/complete-profile/community-norms');
                },
              );
            } else {
              ref.read(notificationServiceProvider).checkPermission().then((granted) {
                if (granted && context.mounted) {
                  context.push('/login/complete-profile/community-norms');
                } else {
                  ref.read(notificationServiceProvider).requestPermission(true).then((grantFixed) {
                    if (grantFixed && context.mounted) {
                      context.push('/login/complete-profile/community-norms');
                    } else {
                      if (context.mounted) {
                        ErrorSnackbar.show(context, config.get<String>('accept-push-notifications-dialog-error'));
                      }
                    }
                  });
                }
              });
            }
          }),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
        ],
      ),
    );
  }
}