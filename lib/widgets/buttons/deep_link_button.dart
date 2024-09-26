import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/overlays/success_snackbar.dart';

class DeepLinkButton extends ConsumerStatefulWidget {
  final String route;

  const DeepLinkButton({super.key, required this.route});

  @override
  ConsumerState<DeepLinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends ConsumerState<DeepLinkButton> {
  bool linkCreated = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.read(remoteConfigServiceProvider);
    return GestureDetector(
      onTap: () async {
        setState(() {
          linkCreated = true;
        });
        SuccessSnackbar.show(context, config.get<String>('copied-link'));
        await Clipboard.setData(ClipboardData(text: widget.route));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: AnimatedRotation(
        turns: linkCreated ? 0.5 : 0,
        duration: const Duration(milliseconds: 500),
        child: CircleAvatar(
          backgroundColor: linkCreated ? Theme.of(context).colorScheme.primary.withAlpha(55) : Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.link,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}