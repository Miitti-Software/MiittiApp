//TODO: Implement new UI

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/confirmdialog.dart';
import 'package:miitti_app/screens/authentication/completeProfile/complete_profile_onboard.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final WebViewController controller = WebViewController();

  Widget createHyperLink(String text, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontFamily: 'Rubik',
          color: AppStyle.lightPurple,
        ),
      ),
    );
  }

  Widget createSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
    );
  }

  Widget createText(String text, {double fontSize = 17.0}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'Rubik',
        color: AppStyle.lightPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asetukset',
              style: TextStyle(
                fontSize: 35,
                color: Colors.white,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  launchUrl(Uri.parse('https://miittiapp.canny.io/')),
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                backgroundColor: WidgetStateProperty.all<Color>(AppStyle.pink),
                minimumSize: WidgetStateProperty.all<Size>(const Size(
                    double.infinity, 120)), // Makes the button 100% wide
              ),
              child: const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the text vertically
                children: [
                  Text(
                    'Anna palautetta',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                    ), // Large text
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ehdota uusia ominaisuuksia, ilmoita ongelmista tai liity keskusteluun parannusehdotuksista!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Rubik',
                  color: Colors.white,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Voit myös liittyä keskusteluun ',
                  ),
                  TextSpan(
                    text: 'Discord-kanavallamme.',
                    style: const TextStyle(
                      color: AppStyle.lightPurple,
                      fontFamily: 'Rubik',
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(Uri.parse('https://discord.gg/aagEzSetdC'));
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            createSectionTitle('Yhteystiedot:'),
            getSomeSpace(10),
            createHyperLink(
              "Seuraa meitä Instagramissa",
              'https://www.instagram.com/miittiapp/',
            ),
            getSomeSpace(10),
            createHyperLink(
              "info@miitti.app",
              'mailto:info@miitti.app',
            ),
            const SizedBox(height: 30),
            createSectionTitle(
              'Dokumentit ja ehdot:',
            ),
            getSomeSpace(10),
            createHyperLink(
              "Käyttöehdot",
              'https://www.miitti.app/kayttoehdot',
            ),
            getSomeSpace(10),
            createHyperLink(
              "Tietosuojaseloste",
              'https://www.miitti.app/tietosuojaseloste',
            ),
            const SizedBox(height: 20),
            createSectionTitle('Tili:'),
            getSomeSpace(10),
            GestureDetector(
                onTap: () async {
                  await ref.read(userStateProvider.notifier).signOut();
                },
                child: createText('Kirjaudu ulos')),
            getSomeSpace(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ref.read(firestoreServiceProvider).isAnonymous) GestureDetector(
                  onTap: () {
                    pushNRemoveUntil(context, const CompleteProfileOnboard());
                  },
                  child: createText('Viimeistele profiili'),
                ),
                GestureDetector(
                  onTap: () => {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const ConfirmDialog(
                          title: 'Varmistus',
                          mainText:
                              'Oletko varma, että haluat poistaa tilisi? Tämä toimenpide on peruuttamaton, ja kaikki tietosi poistetaan pysyvästi.',
                        );
                      },
                    ).then((confirmed) async => {
                      if (confirmed != null && confirmed) {
                        await ref.read(userStateProvider.notifier).deleteUser()
                      }
                    })
                  },
                  child: createText('Poista tili'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            createSectionTitle('Versio'),
            const Text(
              '1.5.4',
              style: TextStyle(
                fontSize: 17,
                fontFamily: 'Rubik',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}
