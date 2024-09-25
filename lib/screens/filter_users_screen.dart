import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/users_filter_settings.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class FilterUsersSettingsPage extends ConsumerWidget {
  const FilterUsersSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final filterSettings = ref.watch(usersFilterSettingsProvider);
    final filterSettingsNotifier = ref.read(usersFilterSettingsProvider.notifier);

    // Fetch activities from remote config
    final activities = config.getActivityTuples();

    return Scaffold(
      appBar: AppBar(
        title: Text(config.get<String>('filter-users-title')),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: AppSizes.minVerticalEdgePadding, left: 16.0, right: 16.0, bottom: AppSizes.minVerticalPadding),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  config.get<String>('filter-users-age-range-label'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  config.get<String>('filter-users-age-range-values'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 2.0),
              ),
              child: RangeSlider(
                values: RangeValues(filterSettings.minAge.toDouble(), filterSettings.maxAge.toDouble()),
                min: 18,
                max: 100,
                divisions: 82,
                labels: RangeLabels('${filterSettings.minAge}', '${filterSettings.maxAge}'),
                onChanged: (RangeValues values) {
                  filterSettingsNotifier.updatePreferences(
                    filterSettings.copyWith(minAge: values.start.toInt(), maxAge: values.end.toInt()),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  config.get<String>('filter-users-same-area-label'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: filterSettings.sameArea,
                    onChanged: (bool value) {
                      filterSettingsNotifier.updatePreferences(
                        filterSettings.copyWith(sameArea: value),
                      );
                    },
                    activeColor: Theme.of(context).primaryColor,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withAlpha(150),
                    inactiveThumbColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: Theme.of(context).colorScheme.surface,
                    trackOutlineColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Text(
              config.get<String>('filter-users-select-interests-label'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.minVerticalPadding),
            Expanded(
              child: PermanentScrollbar(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: activities.map((activity) {
                      final isSelected = filterSettings.interests.contains(activity.item1);
                      return GestureDetector(
                        onTap: () {
                          final updatedInterests = List<String>.from(filterSettings.interests);
                          if (isSelected) {
                            updatedInterests.remove(activity.item1);
                          } else if (updatedInterests.length < 10) {
                            updatedInterests.add(activity.item1);
                          } else {
                            ErrorSnackbar.show(context, config.get<String>('filter-users-max-interests-error'));
                          }
                          filterSettingsNotifier.updatePreferences(
                            filterSettings.copyWith(interests: updatedInterests),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            '${activity.item2.item2} ${activity.item2.item1}', // Display emoji and name
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    ForwardButton(
                      buttonText: config.get<String>('filter-users-save-button'), 
                      onPressed: () {
                        filterSettingsNotifier.savePreferences();
                        ref.read(usersStateProvider.notifier).loadMoreUsers(fullRefresh: true);
                        context.pop(context);
                      }
                    ),
                    const SizedBox(height: AppSizes.minVerticalPadding),
                    BackwardButton(
                      buttonText: config.get<String>('filter-users-cancel-button'), 
                      onPressed: () {
                        context.pop(context);
                      }
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}