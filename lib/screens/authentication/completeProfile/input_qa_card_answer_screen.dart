import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/fields/filled_text_area.dart';

class InputQACardAnswerScreen extends ConsumerStatefulWidget {
  final String question;

  const InputQACardAnswerScreen(this.question, {super.key});

  @override
  _InputQACardAnswerScreenState createState() => _InputQACardAnswerScreenState();
}

class _InputQACardAnswerScreenState extends ConsumerState<InputQACardAnswerScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final userData = ref.read(userDataProvider);
    _controller = TextEditingController(text: userData.qaAnswers[widget.question] ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final config = ref.watch(remoteConfigServiceProvider);
        final userData = ref.watch(userDataProvider);

        return ConfigScreen(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  config.get<String>(widget.question), 
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              FilledTextArea(
                hintText: config.get<String>('input-qa-card-answer-placeholder'),
                controller: _controller,
              ),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-qa-card-answer-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              ForwardButton(
                buttonText: config.get<String>('save-button'),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    userData.qaAnswers[widget.question] = _controller.text;
                  } else {
                    userData.qaAnswers.remove(widget.question);
                  }
                  context.pop();
                },
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(
                buttonText: config.get<String>('back-button'),
                onPressed: () {
                  context.pop();
                },
              ),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
            ],
          ),
        );
      },
    );
  }
}