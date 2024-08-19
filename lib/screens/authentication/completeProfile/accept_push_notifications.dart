// TODO: Make the code nicer and more readable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/confirm_notifications_dialog.dart';

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
            text: "Hyväksyn push-ilmoitukset",
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
            text: "En hyväksy",
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
              showDialog(
                context: context,
                builder: (context) => ConfirmNotificationsDialog(
                  nextPage: () {
                    context.push('/login/complete-profile/community-norms');
                  },
                ),
              );
            } else {
              ref.read(notificationServiceProvider).checkPermission().then((granted) {
                if (granted) {
                  context.push('/login/complete-profile/community-norms');
                } else {
                  ref
                      .read(notificationServiceProvider)
                      .requestPermission(true)
                      .then((grantFixed) {
                    if (grantFixed) {
                      context.push('/login/complete-profile/community-norms');
                    } else {
                      afterFrame(() => showSnackBar(
                            context,
                            'Hyväksy push-ilmoitukset myös laitteeltasi jatkaaksesi!',
                            AppStyle.red,
                          ));
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