import 'package:flutter/material.dart';

class ClusterBubble extends StatelessWidget {
  final int markerCount;

  const ClusterBubble({
    super.key,
    required this.markerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 3.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Theme.of(context).colorScheme.secondary.withAlpha(245),
                  Theme.of(context).colorScheme.secondary.withAlpha(160),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            child: Text(
              "$markerCount",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}