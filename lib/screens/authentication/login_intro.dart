import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
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
    final configStreamAsyncValue = ref.watch(configStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          _gifBackground(context),

          // Handle the different states of the stream
          configStreamAsyncValue.when(
            
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
                ],
              );
            },
            // When the data is loading, show a loading indicator
            loading: () => const Center(child: CircularProgressIndicator()),
            // When the data is an error, show an error message
            error: (error, stack) => Center(child: Text('An error was encountered loading remote configuration: $error \n\nPlease try again or contact support.')),
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
