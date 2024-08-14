import 'package:flutter/material.dart';

class PermanentScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const PermanentScrollbar({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      interactive: true,
      thumbVisibility: true,
      trackVisibility: true,
      minThumbLength: 40,
      thumbColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      trackColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      radius: const Radius.circular(10),
      thickness: 3,
      trackRadius: const Radius.circular(10),
      controller: controller,
      child: child,
    );
  }
}