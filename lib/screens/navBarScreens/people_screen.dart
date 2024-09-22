import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/data_containers/user_list_tile.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _fullRefreshDebounce;
  Timer? _debounce;
  double previousMaxScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    ref.read(usersStateProvider.notifier).loadMoreUsers(fullRefresh: true);
    _scrollController.addListener(_onScroll);
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
        ref.read(usersStateProvider.notifier).loadMoreUsers();
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
    final people = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.get<String>('people-screen-title')),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface),
            iconSize: 36,
            onPressed: () {
              context.go('/people/filter');
            },
          ),
        ],
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
            await ref.read(usersStateProvider.notifier).loadMoreUsers(fullRefresh: true);
            completer.complete();
            return completer.future;
          },
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          child: PermanentScrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: people.length,
              cacheExtent: 100,
              itemBuilder: (BuildContext context, int index) {
                return UserListTile(
                  user: people[index],
                  onTap: () {
                    context.go('/people/user/${people[index].uid}');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

