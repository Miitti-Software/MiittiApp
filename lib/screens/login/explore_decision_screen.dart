//TODO: Refactor

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/login/completeProfile/complete_profile_onboard.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

class ExploreDecisionScreen extends ConsumerWidget {
  const ExploreDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeScaffold(
      ref.watch(providerLoading)
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
                  'Tervetuloa Miittiin! 🎊',
                  textAlign: TextAlign.center,
                  style: AppStyle.title,
                ),

                //body
                Text(
                  'Haluaisitko seuraavaksi suorittaa profiilin luonnin loppuun, vai tutustua\n sovellukseen?',
                  textAlign: TextAlign.center,
                  style: AppStyle.body,
                ),

                const Spacer(),

                //continue building profile button
                MyButton(
                  buttonText: 'Jatka profiilin luomista',
                  onPressed: () {
                    //continue profile
                    pushNRemoveUntil(context, const CompleteProfileOnboard());
                  },
                ),

                //get to know the app button
                TextButton(
                  onPressed: () => pushNRemoveUntil(
                    context,
                    const IndexPage(),
                  ),
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
