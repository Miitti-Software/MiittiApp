import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/language_radio_buttons.dart';
import 'package:miitti_app/widgets/dynamic_rich_text.dart';

import 'package:miitti_app/state/service_providers.dart';

// The first page that a user sees when opening the app without being signed in
class LoginIntro extends ConsumerWidget {
  const LoginIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider
    final configStreamAsyncValue = ref.watch(configStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          _background(context),

          // Handle the different states of the stream
          configStreamAsyncValue.when(
            data: (data) {
              // Cast the dynamic list containing the rich text to List<Map<String, dynamic>>
              final richTextData = (data['rich-terms-of-usage-notice'] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  SvgPicture.asset('images/miittiLogo.svg',),
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
                    width: Sizes.fullContentWidth,
                    child: DynamicRichText(
                      richTextData: richTextData,
                      textStyle: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  const LanguageRadioButtons(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
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
