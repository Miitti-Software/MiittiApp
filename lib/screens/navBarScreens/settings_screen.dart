//TODO: Implement new UI

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/confirmdialog.dart';
import 'package:miitti_app/screens/login/completeProfile/complete_profile_onboard.dart';
import 'package:miitti_app/screens/login/login_intro.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WebViewController controller = WebViewController();

  Widget createHyperLink(String text, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17.sp,
          fontFamily: 'Rubik',
          color: AppStyle.lightPurpleColor,
        ),
      ),
    );
  }

  Widget createSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
    );
  }

  Widget createText(String text, {double fontSize = 17.0}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize.sp,
        fontFamily: 'Rubik',
        color: AppStyle.lightPurpleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asetukset',
                style: TextStyle(
                  fontSize: 35.sp,
                  color: Colors.white,
                  fontFamily: 'Sora',
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://miittiapp.canny.io/')),
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  backgroundColor:
                      WidgetStateProperty.all<Color>(AppStyle.pink),
                  minimumSize: WidgetStateProperty.all<Size>(const Size(
                      double.infinity, 120)), // Makes the button 100% wide
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the text vertically
                  children: [
                    Text(
                      'Anna palautetta',
                      style: TextStyle(
                        fontSize: 22.sp,
                        color: Colors.white,
                      ), // Large text
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Ehdota uusia ominaisuuksia, ilmoita ongelmista tai liity keskusteluun parannusehdotuksista!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.sp,
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
                        color: AppStyle.lightPurpleColor,
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
              SizedBox(height: 30.h),
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
              SizedBox(height: 30.h),
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
              SizedBox(height: 20.h),
              createSectionTitle('Tili:'),
              getSomeSpace(10),
              GestureDetector(
                  onTap: () => ap.userSignOut().then(
                        (value) =>
                            pushNRemoveUntil(context, const LoginIntro()),
                      ),
                  child: createText('Kirjaudu ulos')),
              getSomeSpace(10),
              ap.isAnonymous
                  ? GestureDetector(
                      onTap: () {
                        pushNRemoveUntil(
                            context, const CompleteProfileOnboard());
                      },
                      child: createText('Viimeistele profiili'),
                    )
                  : GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const ConfirmDialog(
                              title: 'Varmistus',
                              mainText:
                                  'Oletko varma, että haluat poistaa tilisi? Tämä toimenpide on peruuttamaton, ja kaikki tietosi poistetaan pysyvästi.',
                            );
                          },
                        ).then((confirmed) {
                          if (confirmed != null && confirmed) {
                            ap.removeUser(ap.miittiUser.uid).then((value) {
                              showSnackBar(context, value.$2,
                                  value.$1 ? Colors.green : Colors.red);
                              if (value.$1) {
                                ap.userSignOut().then(
                                      (value) => pushNRemoveUntil(
                                          context, const LoginIntro()),
                                    );
                              }
                            });
                          }
                        });
                      },
                      child: createText('Poista tili'),
                    ),
              SizedBox(height: 30.h),
              createSectionTitle('Versio'),
              Text(
                '1.5.4',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: 'Rubik',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
