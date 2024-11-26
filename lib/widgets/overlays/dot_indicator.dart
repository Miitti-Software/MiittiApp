import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget {
  final bool requestOrJoin;

  const DotIndicator({
    Key? key,
    required this.requestOrJoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: requestOrJoin ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.surface,
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}