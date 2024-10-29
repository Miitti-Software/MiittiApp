import 'package:miitti_app/services/analytics_service.dart';
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
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

class InputActivitiesScreen extends ConsumerStatefulWidget {
  const InputActivitiesScreen({super.key});

  @override
  _InputActivitiesScreenState createState() => _InputActivitiesScreenState();
}

class _InputActivitiesScreenState extends ConsumerState<InputActivitiesScreen> {
  Set<String> favoriteActivities = <String>{};
  List<Tuple2<String, Tuple2<String, String>>> allActivities = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    favoriteActivities = ref.read(userStateProvider).data.favoriteActivities.toSet();
  }

  Future<void> _loadActivities() async {
    setState(() {
      allActivities = ref.read(remoteConfigServiceProvider).getActivityTuples();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    final isAnonymous = ref.watch(userStateProvider).isAnonymous;
    ref.read(analyticsServiceProvider).logScreenView('input_activities_screen');

    return Stack(
      children: [
        ConfigScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              Text(config.get<String>('input-activities-title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-activities-disclaimer'),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              
              const SizedBox(height: AppSizes.minVerticalPadding),
              Expanded(
                child: PermanentScrollbar(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: GridView.builder(
                      itemCount: allActivities.map((e) => e.item1).length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppSizes.minVerticalPadding * 2,
                        mainAxisSpacing: AppSizes.minVerticalPadding,
                      ),
                      itemBuilder: (context, index) {
                        final activity = allActivities[index];
                        final isSelected = favoriteActivities.contains(activity.item1);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (favoriteActivities.contains(activity.item1)) {
                                favoriteActivities.remove(activity.item1);
                                userState.update((state) => state.copyWith(
                                  data: userData.removeFavoriteActivity(activity.item1),
                                ));
                              } else {
                                favoriteActivities.add(activity.item1);
                                userState.update((state) => state.copyWith(
                                  data: userData.addFavoriteActivity(activity.item1),
                                ));
                              }
                            });
                          },
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.minVerticalPadding,
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  activity.item2.item2,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  activity.item2.item1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              if (isAnonymous)
                ForwardButton(
                  buttonText: config.get<String>('forward-button'),
                  onPressed: () {
                    if (favoriteActivities.isNotEmpty) {
                      context.push('/login/complete-profile/push-notifications');
                    } else {
                      ErrorSnackbar.show(
                          context, config.get<String>('invalid-activities-missing'));
                    }
                  },
                )
              else
                ForwardButton(
                  buttonText: config.get<String>('save-button'),
                  onPressed: () async {
                    if (favoriteActivities.isNotEmpty) {
                      setState(() {
                        isLoading = true;
                      });
                      userState.update((state) => state.copyWith(
                        data: userData.copyWith(favoriteActivities: favoriteActivities.toList())
                      ));
                      await userState.updateUserData();
                      setState(() {
                        isLoading = false;
                      });
                      context.pop();
                    } else {
                      ErrorSnackbar.show(
                          context, config.get<String>('invalid-activities-missing'));
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
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}