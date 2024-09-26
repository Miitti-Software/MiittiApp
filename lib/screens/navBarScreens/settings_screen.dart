import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/delete_account_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/language_radio_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userState = ref.watch(userStateProvider.notifier);
    ref.watch(remoteConfigStreamProvider);
    final isNotificationsEnabled = ref.watch(pushNotificationServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              _buildStyledListTile(
                context,
                title: config.get<String>('settings-join-requests-title'),
                subtitle: config.get<String>('settings-join-requests-body'),
                icon: Icons.group_add_outlined,
                onTap: () {
                  context.go('/chats');
                },
              ),
              _buildStyledListTile(
                context,
                title: config.get<String>('settings-feedback-title'),
                subtitle: config.get<String>('settings-feedback-body'),
                icon: Icons.diamond_outlined,
                onTap: () {
                  _launchURL('https://www.miitti.app/feedback');
                },
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              StyledButton(
                text: config.get<String>('settings-contact-button'),
                icon: Icons.contact_mail_outlined,
                onTap: () {
                  _launchURL('mailto:info@miitti.app');
                },
                color: Theme.of(context).colorScheme.primary,
              ),
              StyledButton(
                text: config.get<String>('settings-terms-of-service-button'),
                icon: Icons.description_outlined,
                onTap: () {
                  _launchURL('https://www.miitti.app/kayttoehdot');
                },
                color: Theme.of(context).colorScheme.primary,
              ),
              StyledButton(
                text: config.get<String>('settings-privacy-policy-button'),
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  _launchURL('https://www.miitti.app/tietosuojaseloste');
                },
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 5),
              const DeleteAccountButton(),
              const SizedBox(height: AppSizes.minVerticalPadding),
              Text(
                '${config.get<String>('settings-current-version-text')} $appVersion',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              Row(
                children: [
                  Switch(
                    value: isNotificationsEnabled,
                    onChanged: (bool value) async {
                      await ref.read(pushNotificationServiceProvider.notifier).setNotificationsEnabled(value);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(config.get<String>('settings-push-notifications-title')),
                ],
              ),
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              const LanguageRadioButtons(),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              Center(
                child: ForwardButton(
                  onPressed: () async {
                    context.go('/login');
                    await userState.signOut();
                  },
                  buttonText: config.get<String>('settings-sign-out-button'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledListTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(25),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
        trailing: Icon(icon, size: 40, color: Colors.white),
        onTap: onTap,
      ),
    );
  }

  void _launchURL(String url) async {
    await launchUrl(Uri.parse(url));
  }
}

class StyledButton extends ConsumerWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const StyledButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
























// //TODO: Implement new UI

// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:miitti_app/constants/app_style.dart';
// import 'package:miitti_app/state/service_providers.dart';
// import 'package:miitti_app/state/user.dart';
// import 'package:miitti_app/widgets/buttons/delete_account_button.dart';
// import 'package:miitti_app/screens/authentication/completeProfile/complete_profile_onboard.dart';
// import 'package:miitti_app/functions/utils.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class SettingsScreen extends ConsumerStatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends ConsumerState<SettingsScreen> {
//   final WebViewController controller = WebViewController();

//   Widget createHyperLink(String text, String url) {
//     return InkWell(
//       onTap: () => launchUrl(Uri.parse(url)),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 17,
//           fontFamily: 'Rubik',
//           color: AppStyle.lightPurple,
//         ),
//       ),
//     );
//   }

//   Widget createSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 13,
//         fontFamily: 'Poppins',
//         color: Colors.white,
//       ),
//     );
//   }

//   Widget createText(String text, {double fontSize = 17.0}) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: fontSize,
//         fontFamily: 'Rubik',
//         color: AppStyle.lightPurple,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Asetukset',
//               style: TextStyle(
//                 fontSize: 35,
//                 color: Colors.white,
//                 fontFamily: 'Sora',
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () =>
//                   launchUrl(Uri.parse('https://miittiapp.canny.io/')),
//               style: ButtonStyle(
//                 shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                   RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15.0),
//                   ),
//                 ),
//                 backgroundColor: WidgetStateProperty.all<Color>(AppStyle.pink),
//                 minimumSize: WidgetStateProperty.all<Size>(const Size(
//                     double.infinity, 120)), // Makes the button 100% wide
//               ),
//               child: const Column(
//                 mainAxisAlignment:
//                     MainAxisAlignment.center, // Center the text vertically
//                 children: [
//                   Text(
//                     'Anna palautetta',
//                     style: TextStyle(
//                       fontSize: 22,
//                       color: Colors.white,
//                     ), // Large text
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     'Ehdota uusia ominaisuuksia, ilmoita ongelmista tai liity keskusteluun parannusehdotuksista!',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),
//             RichText(
//               textAlign: TextAlign.center,
//               text: TextSpan(
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontFamily: 'Rubik',
//                   color: Colors.white,
//                 ),
//                 children: <TextSpan>[
//                   const TextSpan(
//                     text: 'Voit myös liittyä keskusteluun ',
//                   ),
//                   TextSpan(
//                     text: 'Discord-kanavallamme.',
//                     style: const TextStyle(
//                       color: AppStyle.lightPurple,
//                       fontFamily: 'Rubik',
//                     ),
//                     recognizer: TapGestureRecognizer()
//                       ..onTap = () {
//                         launchUrl(Uri.parse('https://discord.gg/aagEzSetdC'));
//                       },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             createSectionTitle('Yhteystiedot:'),
//             getSomeSpace(10),
//             createHyperLink(
//               "Seuraa meitä Instagramissa",
//               'https://www.instagram.com/miittiapp/',
//             ),
//             getSomeSpace(10),
//             createHyperLink(
//               "info@miitti.app",
//               'mailto:info@miitti.app',
//             ),
//             const SizedBox(height: 30),
//             createSectionTitle(
//               'Dokumentit ja ehdot:',
//             ),
//             getSomeSpace(10),
//             createHyperLink(
//               "Käyttöehdot",
//               'https://www.miitti.app/kayttoehdot',
//             ),
//             getSomeSpace(10),
//             createHyperLink(
//               "Tietosuojaseloste",
//               'https://www.miitti.app/tietosuojaseloste',
//             ),
//             const SizedBox(height: 20),
//             createSectionTitle('Tili:'),
//             getSomeSpace(10),
//             GestureDetector(
//                 onTap: () async {
//                   await ref.read(userStateProvider.notifier).signOut();
//                 },
//                 child: createText('Kirjaudu ulos')),
//             getSomeSpace(10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (ref.read(firestoreServiceProvider).isAnonymous) GestureDetector(
//                   onTap: () {
//                     pushNRemoveUntil(context, const CompleteProfileOnboard());
//                   },
//                   child: createText('Viimeistele profiili'),
//                 ),
//                 const DeleteAccountButton(),
//               ],
//             ),
//             const SizedBox(height: 30),
//             createSectionTitle('Versio'),
//             const Text(
//               '1.5.4',
//               style: TextStyle(
//                 fontSize: 17,
//                 fontFamily: 'Rubik',
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     )
//     );
//   }
// }
