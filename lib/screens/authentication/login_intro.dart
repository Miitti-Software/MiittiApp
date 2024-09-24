import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/widgets/background_gradient.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/language_radio_buttons.dart';
import 'package:miitti_app/widgets/dynamic_rich_text.dart';
import 'package:miitti_app/state/service_providers.dart';

/// The first page that a user sees when opening the app without being signed in
class LoginIntroScreen extends ConsumerWidget {
  const LoginIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider
    final configStreamAsyncValue = ref.watch(remoteConfigStreamProvider);
    ref.read(analyticsServiceProvider).logScreenView('login_intro_screen');

    return Scaffold(
      body: Stack(
        children: [
          _gifBackground(context),

          // Handle the different states of the stream
          configStreamAsyncValue.when(                                // TODO: Works as intended when opening the app while not signed in but gets stuck loading when signing out after a hot refresh if configStreamProvider is not called in MapScreen
            
            // When the data is loaded, build the UI with the data
            data: (data) {

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  SvgPicture.asset(AppGraphics.miittiLogo),
                  const SizedBox(height: 15,),
                  Text(
                    data['slogan'],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 15,),
                  const Spacer(),
                  ForwardButton(
                    buttonText: data['auth-call-to-action'],
                    onPressed: () => context.go('/login/authenticate'), 
                  ),
                  const SizedBox(height: 15,),
                  SizedBox(
                    width: AppSizes.fullContentWidth,
                    child: DynamicRichText(
                      richTextData: (data['rich-terms-of-usage-notice'] as List).map((item) => item as Map<String, dynamic>).toList(),
                      textStyle: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  const LanguageRadioButtons(),
                  const SizedBox(height: AppSizes.minVerticalEdgePadding),
                ],
              );
            },
            // When the data is loading, show a loading indicator
            loading: () { return const Center(child: CircularProgressIndicator()); },
            // When the data is an error, show an error message (Fetching the error message about failing to fetch values from remote config might be slightly suboptimal but at least it uses .get instead of the stream)
            error: (error, stack) {
              if (kDebugMode) debugPrint('Error in login intro config stream: $error');
              return Center(
                child: Text(
                  '${ref.read(remoteConfigServiceProvider).get<String>("login-intro-config-stream")} ${ref.read(remoteConfigServiceProvider).get<String>("generic-error-action-prompt")}'
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Background gif with overlaid background gradient
  Widget _gifBackground(context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                AppGraphics.splashBackground,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const BackgroundGradient(),
      ]
    );
  }
}
