import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
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
    ref.read(analyticsServiceProvider).logScreenView('create_activity_category_screen');

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
                  child: GridView.extent(
                    maxCrossAxisExtent: 120,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 20.0,
                    childAspectRatio: 0.8,
                    children: allActivities.map((activity) {
                      final isSelected = selectedActivity == activity.item1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedActivity == activity.item1) {
                              selectedActivity = null;
                              createActivityState.update((state) => state.copyWith(category: null));
                            } else {
                              selectedActivity = activity.item1;
                              createActivityState.update((state) => state.copyWith(category: activity.item1));
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  activity.item2.item2,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  activity.item2.item1,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
                  buttonText: config.get<String>('forward-button'),
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
                    buttonText: config.get<String>('back-button'),
                    onPressed: () => context.go('/')
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
