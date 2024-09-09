import 'package:flutter/material.dart';

class ModalPage<T> extends Page<T> {
  const ModalPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    builder: (context) => Wrap(
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
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
  );
}
