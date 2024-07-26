//TODO: Refactor

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

class ExploreDecisionScreen extends ConsumerWidget {
  const ExploreDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeScaffold(
      ref.watch(providerLoading)                // TODO: User with no account gets stuck because of this combined with app_router call
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                const Spacer(),
                //title
                Text(
                  ref.watch(remoteConfigServiceProvider).get<String>('first-auth-welcome-title'),
                  textAlign: TextAlign.center,
                  style: AppStyle.title,
                ),

                //body
                Text(
                  ref.watch(remoteConfigServiceProvider).get<String>('first-auth-welcome-subtitle'),
                  textAlign: TextAlign.center,
                  style: AppStyle.body,
                ),

                const Spacer(),

                //continue building profile button
                MyButton(
                  buttonText: 'Jatka profiilin luomista',
                  onPressed: () {
                    context.go('/login/complete-profile');
                  },
                ),

                //get to know the app button
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    'Tutustu sovellukseen',
                    style: AppStyle.body,
                  ),
                ),

                //warning
                Text(
                  'Huom! Kaikki sovelluksen ominaisuudet eivät ole käytettävissä,\n ennen kuin profiilisi on viimeistelty. ',
                  textAlign: TextAlign.center,
                  style: AppStyle.warning.copyWith(color: AppStyle.red),
                )
              ],
            ),
    );
  }
}
