import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class InfiniteList<T> extends ConsumerStatefulWidget {
  final List<T> dataSource;
  final Future<void> Function()? loadMoreFunction;
  final Future<void> Function()? refreshFunction;
  final Widget Function(BuildContext, int) listTileBuilder;
  final ScrollController? scrollController;

  const InfiniteList({
    Key? key,
    required this.dataSource,
    required this.listTileBuilder,
    this.scrollController,
    this.loadMoreFunction,
    this.refreshFunction,
  }) : super(key: key);

  @override
  _InfiniteListState<T> createState() => _InfiniteListState<T>();
}

class _InfiniteListState<T> extends ConsumerState<InfiniteList<T>> {
  Timer? _debounce;
  Timer? _fullRefreshDebounce;
  double previousMaxScrollPosition = 0.0;
  late ScrollController _internalScrollController;

  @override
  void initState() {
    super.initState();
    _internalScrollController = widget.scrollController ?? ScrollController();
    _internalScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _internalScrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _internalScrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.loadMoreFunction == null) return;

    final scrollPosition = _internalScrollController.position.pixels;
    final maxScrollExtent = _internalScrollController.position.maxScrollExtent;
    final threshold = maxScrollExtent * 0.7;

    if (scrollPosition >= threshold && scrollPosition > previousMaxScrollPosition) {
      if (_debounce?.isActive ?? false) {
        _debounce?.cancel();
      } else {
        widget.loadMoreFunction!();
      }

      previousMaxScrollPosition = max(scrollPosition, previousMaxScrollPosition);
      _debounce = Timer(const Duration(milliseconds: 200), () {
        _debounce = null;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final completer = Completer<void>();
    if (_fullRefreshDebounce?.isActive ?? false) {
      completer.complete();
      return completer.future;
    }
    _fullRefreshDebounce = Timer(const Duration(seconds: 3), () {});
    if (widget.refreshFunction != null) {
      await widget.refreshFunction!();
    }
    completer.complete();
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: PermanentScrollbar(
        controller: _internalScrollController,
        child: ListView.builder(
          controller: _internalScrollController,
          itemCount: widget.dataSource.length,
          cacheExtent: 100,
          itemBuilder: widget.listTileBuilder,
        ),
      ),
    );
  }
}