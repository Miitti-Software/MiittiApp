import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/dynamic_rich_text.dart';

import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/service_providers.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/screens/authentication/login/login_auth.dart';

// The first page that a user sees when opening the app without being signed in
class LoginIntro extends ConsumerWidget {
  const LoginIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          _background(context),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              SvgPicture.asset('images/miittiLogo.svg',),
              const SizedBox(height: 15,),
              Text(
                ref.read(remoteConfigService).get<String>('slogan'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              ForwardButton(
                buttonText: ref.read(remoteConfigService).get<String>('auth-call-to-action'),
                onPressed: () => pushPage(context, const LoginAuth()),                            // TODO: Switch navigation solution
              ),
              const SizedBox(height: 15,),
              Center(
                child: SizedBox(
                  width: Sizes.fullContentWidth,
                  child: DynamicRichText(
                    richTextData: ref.read(remoteConfigService).getRichText('rich-terms-of-usage-notice'),
                    textStyle: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Spacer(),
              getLanguagesButtons(),                // TODO: Implement language selection
            ],
          ),
        ],
      ),
    );
  }

  // Background gif under a partially transparent surface color
  Widget _background(context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(
            "images/splashscreen.gif",
          ),
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.surface.withOpacity(0.2),
            BlendMode.dstATop,
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
