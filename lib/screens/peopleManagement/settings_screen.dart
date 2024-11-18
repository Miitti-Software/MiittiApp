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
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
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
                      try {
                        await ref
                          .read(pushNotificationServiceProvider.notifier)
                          .setNotificationsEnabled(value);
                      } catch (e) {
                        ErrorSnackbar.show(context, 'Failed to ${value ? 'enable' : 'disable'} notifications');
                      }
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
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      await userState.signOut();
                    });
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