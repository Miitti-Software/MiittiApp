import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/create_activity_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:tuple/tuple.dart';

class ChooseActivityCategoryScreen extends ConsumerStatefulWidget {
  const ChooseActivityCategoryScreen({super.key});

  @override
  _ChooseActivityCategoryScreenState createState() =>
      _ChooseActivityCategoryScreenState();
}

class _ChooseActivityCategoryScreenState
    extends ConsumerState<ChooseActivityCategoryScreen> {
  String? selectedActivity;
  List<Tuple2<String, Tuple2<String, String>>> allActivities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
    selectedActivity = ref.read(createActivityStateProvider).category;
  }

  Future<void> _loadActivities() async {
    setState(() {
      allActivities = ref.read(remoteConfigServiceProvider).getActivityTuples();
    });
  }

  @override
  Widget build(BuildContext context) {
    final createActivityState = ref.read(createActivityStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);

    return Scaffold(
      body: Center(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      config.get<String>('create-activity-category-title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                Expanded(
                  child: GridView.builder(
                    itemCount: allActivities.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemBuilder: (context, index) {
                      final activity = allActivities[index];
                      final isSelected = selectedActivity == activity.item1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedActivity == activity.item1) {
                              selectedActivity = null;
                              createActivityState.update(
                                  (state) => state.copyWith(category: null));
                            } else {
                              selectedActivity = activity.item1;
                              createActivityState.update((state) =>
                                  state.copyWith(category: activity.item1));
                            }
                          });
                        },
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                activity.item2.item2,
                                style: const TextStyle(fontSize: 32),
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    textAlign: TextAlign.center,
                                    activity.item2.item1,
                                    overflow: TextOverflow.visible,
                                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                LinearProgressIndicator(
                  value: 0.25,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                const SizedBox(height: AppSizes.minVerticalPadding),
                ForwardButton(
                  buttonText: 'Next',
                  onPressed: () {
                    if (selectedActivity != null) {
                      context.go('/create-activity/location');
                    } else {
                      ErrorSnackbar.show(context, config.get<String>('invalid-activity-category-missing'));
                    }
                  },
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                BackwardButton(
                    buttonText: 'Back',
                    onPressed: () => context.go('/')
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
