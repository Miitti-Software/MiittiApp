import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class InfiniteList<T> extends ConsumerStatefulWidget {
  final List<T> dataSource;
  final Future<void> Function() refreshFunction;
  final Widget Function(BuildContext, int) listTileBuilder;
  final ScrollController scrollController;
  final Future<void> Function() loadMoreFunction;

  const InfiniteList({
    Key? key,
    required this.dataSource,
    required this.refreshFunction,
    required this.listTileBuilder,
    required this.scrollController,
    required this.loadMoreFunction,
  }) : super(key: key);

  @override
  _InfinityListState<T> createState() => _InfinityListState<T>();
}

class _InfinityListState<T> extends ConsumerState<InfiniteList<T>> {
  Timer? _fullRefreshDebounce;
  Timer? _debounce;
  double previousMaxScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = widget.scrollController.position.pixels;
    final maxScrollExtent = widget.scrollController.position.maxScrollExtent;
    final threshold = maxScrollExtent * 0.7;

    if (scrollPosition >= threshold && scrollPosition > previousMaxScrollPosition) {
      if (_debounce?.isActive ?? false) {
        _debounce?.cancel();
      } else {
        widget.loadMoreFunction();
      }

      previousMaxScrollPosition = max(scrollPosition, previousMaxScrollPosition);
      _debounce = Timer(const Duration(milliseconds: 200), () {
        _debounce = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();
        if (_fullRefreshDebounce?.isActive ?? false) {
          completer.complete();
          return completer.future;
        }
        _fullRefreshDebounce = Timer(const Duration(seconds: 3), () {});
        await widget.refreshFunction();
        completer.complete();
        return completer.future;
      },
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: PermanentScrollbar(
        controller: widget.scrollController,
        child: ListView.builder(
          controller: widget.scrollController,
          itemCount: widget.dataSource.length,
          cacheExtent: 100,
          itemBuilder: widget.listTileBuilder,
        ),
      ),
    );
  }
}