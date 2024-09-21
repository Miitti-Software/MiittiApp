import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';

/// A welcome screen for a user who has just signed up, prompting them to complete their profile but also letting them to explore the app instead if they want.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        children: [
          const Spacer(),

          Text(
            config.get<String>('first-auth-welcome-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          Text(
            config.get<String>('first-auth-welcome-subtitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 100),

          ForwardButton(
            buttonText: config.get<String>('complete-profile-button'),
            onPressed: () => context.push('/login/complete-profile'),
          ),

          TextButton(
            onPressed: () => context.go('/'),
            child: Text(
              config.get<String>('complete-profile-skip-button'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const Spacer(),

          Text(
            config.get<String>('complete-profile-skip-notice'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.error),
          ),

          const SizedBox(height: 45),
        ],
      ),
    );
  }
}
