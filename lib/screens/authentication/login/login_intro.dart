import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/service_providers.dart';

import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/screens/authentication/login/login_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';

// The first page that an user 
class LoginIntro extends ConsumerWidget {
  const LoginIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          _background(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              getMiittiLogo,
              gapH15,
              Text(
                ref.read(remoteConfigService).get<String>('slogan'),
                textAlign: TextAlign.center,
                style: AppStyle.body,
              ),
              const Spacer(),
              MyButton(
                buttonText: ref.read(remoteConfigService).get<String>('auth-call-to-action'),
                onPressed: () => pushPage(context, const LoginAuth()),
              ),
              gapH8,
              _richText(),
              const Spacer(),
              getLanguagesButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _background() {
    //background gif with 0.8 opacity purple
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(
            "images/splashscreen.gif",
          ),
          colorFilter: ColorFilter.mode(
            AppStyle.black.withOpacity(0.2),
            BlendMode.dstATop,
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _richText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppStyle.warning,
        children: <TextSpan>[
          const TextSpan(
              text:
                  'Ottamalla Miitti App -sovelluksen käyttöön hyväksyt samalla voimassaolevan '),
          TextSpan(
            text: 'tietosuojaselosteen',
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  launchUrlString('https://www.miitti.app/tietosuojaseloste'),
            style: const TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' sekä '),
          TextSpan(
            recognizer: TapGestureRecognizer()
              ..onTap =
                  () => launchUrlString('https://www.miitti.app/kayttoehdot'),
            text: 'käyttöehdot',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
