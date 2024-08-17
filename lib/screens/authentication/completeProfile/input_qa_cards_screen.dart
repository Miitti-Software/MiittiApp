import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/error_snackbar.dart';

class InputQACardsScreen extends ConsumerStatefulWidget {
  const InputQACardsScreen({super.key});

  @override
  _InputQACardsScreenState createState() => _InputQACardsScreenState();
}

class _InputQACardsScreenState extends ConsumerState<InputQACardsScreen> {
  List<String> qaCategories = ['qa_category_1', 'qa_category_2', 'qa_category_3'];
  String qaCategory = 'qa_category_1';
  List<Tuple2<String, String>> qaCards = [];
  List<Tuple2<String, String>> answeredQACards = [];

  @override
  void initState() {
    super.initState();
    _loadQACards();
  }

  void _loadQACards() {
    qaCards = ref.read(remoteConfigServiceProvider).getTuplesList<String>(qaCategory);
    final userData = ref.read(userDataProvider);
    answeredQACards = qaCards.where(
      (qaCard) => userData.qaAnswers.containsKey(qaCard.item1)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
          Text(config.get<String>('input-qa-cards-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-qa-cards-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.minVerticalPadding),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: qaCategories.map((String category) {
                return ChoiceButton(
                  text: config.get<String>(category),
                  isSelected: qaCategory == category,
                  onSelected: (bool selected) {
                    if (!selected) {
                      setState(() {
                        qaCategory = category;
                        _loadQACards();
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSizes.minVerticalPadding),
          Expanded(
            child: PermanentScrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: qaCards.length,
                itemBuilder: (context, index) {
                  final qaCard = qaCards[index];
                  final isSelected = answeredQACards.contains(qaCard);
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        bottom: isSelected 
                        ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1) 
                        : BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    margin: const EdgeInsets.only(bottom: 8, right: 10),
                    child: ListTile(
                      titleTextStyle: Theme.of(context).textTheme.labelMedium,
                      trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                      minVerticalPadding: 6,
                      minTileHeight: 1,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      title: Text(qaCard.item2),
                      onTap: () async {
                        await context.push('/login/complete-profile/qa-card/${qaCard.item1}');
                        setState(() {
                          _loadQACards();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.verticalSeparationPadding),
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (answeredQACards.isNotEmpty) {
                context.push('/');
              } else {
                ErrorSnackbar.show(
                    context, config.get<String>('invalid-qa-cards-missing'));
              }
            },
          ),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(
            buttonText: config.get<String>('back-button'),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
        ],
      ),
    );
  }
}