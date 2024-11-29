import 'package:flutter/material.dart';

class ModalPage<T> extends Page<T> {
  const ModalPage({
    super.key, 
    required this.child,
    this.onDismiss,
  });

  final Widget child;
  final VoidCallback? onDismiss;

  @override
  Route<T> createRoute(BuildContext context) => CustomModalBottomSheetRoute<T>(
    settings: this,
    modalBarrierColor: Colors.transparent,
    builder: (context) => PopScope(
      canPop: true,
      child: Wrap(
        children: [
          Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    onDismiss: onDismiss,
  );
}

class CustomModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  final VoidCallback? onDismiss;

  CustomModalBottomSheetRoute({
    required super.builder,
    super.capturedThemes,
    super.barrierLabel,
    super.backgroundColor,
    super.elevation,
    super.isDismissible = true,
    super.modalBarrierColor,
    super.enableDrag = true,
    super.settings,
    super.isScrollControlled = false,
    this.onDismiss,
  });

  @override
  bool get barrierDismissible => true;

  @override
  void didComplete(T? result) {
    onDismiss?.call();
    super.didComplete(result);
  }
}
