import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/activities_state.dart';
import 'package:miitti_app/widgets/data_containers/activity_list_tile.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class OthersActivitiesScreen extends ConsumerStatefulWidget {
  const OthersActivitiesScreen({super.key});

  @override
  _OthersActivitiesScreenState createState() => _OthersActivitiesScreenState();
}

class _OthersActivitiesScreenState extends ConsumerState<OthersActivitiesScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _fullRefreshDebounce;
  Timer? _debounce;
  double previousMaxScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial activities
    ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final threshold = maxScrollExtent * 0.7;

    if (scrollPosition >= threshold && scrollPosition > previousMaxScrollPosition) {
      if (_debounce?.isActive ?? false) {
        _debounce?.cancel();
      } else {
        ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities();
      }

      previousMaxScrollPosition = max(scrollPosition, previousMaxScrollPosition);
      _debounce = Timer(const Duration(milliseconds: 200), () {
        _debounce = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final activities = ref.watch(activitiesStateProvider).othersActivities;

    return ref.read(userStateProvider).isAnonymous
        ? const AnonymousUserScreen()
        : Scaffold(
            appBar: AppBar(
              title: Text(config.get<String>('others-activities-screen-title')),
            ),
            body: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.only(top: AppSizes.minVerticalEdgePadding),
              child: RefreshIndicator(
                onRefresh: () async {
                  final completer = Completer<void>();
                  if (_fullRefreshDebounce?.isActive ?? false) {
                    completer.complete();
                    return completer.future;
                  }
                  _fullRefreshDebounce = Timer(const Duration(seconds: 3), () {});
                  await ref.read(activitiesStateProvider.notifier).loadMoreParticipatingActivities(fullRefresh: true);
                  completer.complete();
                  return completer.future;
                },
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                child: PermanentScrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: activities.length,
                    cacheExtent: 100,
                    itemBuilder: (BuildContext context, int index) {
                      return ActivityListTile(
                        activities[index],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
  }
}