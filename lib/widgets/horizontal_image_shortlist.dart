import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:miitti_app/services/cache_manager_service.dart';

// TODO: Add navigation to individual items from images and to a list from stack

class HorizontalImageShortlist extends StatelessWidget {
  final List<String> imageUrls;

  const HorizontalImageShortlist({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: imageUrls.length < 5
          ? Row(children: _buildSeparatedCircles(context))
          : Stack(children: _buildOverlappingCircles(context)),
    );
  }

  List<Widget> _buildSeparatedCircles(BuildContext context) {
    List<Widget> circles = [];
    int imageCount = imageUrls.length;

    for (int i = 0; i < imageCount; i++) {
      circles.add(_buildCircle(imageUrls[i]));
      if (i < imageCount - 1) {
        circles.add(const SizedBox(width: 8));
      }
    }

    return circles;
  }

  Widget _buildCircle(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(
          imageUrl,
          cacheManager: ProfilePicturesCacheManager().instance,
          ),
        radius: 20,
      ),
    );
  }

  List<Widget> _buildOverlappingCircles(BuildContext context) {
    List<Widget> circles = [];
    int imageCount = imageUrls.length;

    for (int i = 0; i < imageCount && i < 4; i++) {
      circles.add(_buildPositionedCircle(imageUrls[i], i * 24.0));
    }

    if (imageCount > 4) {
      circles.add(_buildPositionedCircle(imageUrls[4], 4 * 24.0));
      circles.add(_buildRemainingCircle(context, imageCount - 4, 4 * 24.0));
    }

    return circles;
  }

  Widget _buildPositionedCircle(String imageUrl, double leftPosition) {
    return Positioned(
      left: leftPosition,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            imageUrl,
            cacheManager: ProfilePicturesCacheManager().instance,
            ),
          radius: 20,
        ),
      ),
    );
  }

  Widget _buildRemainingCircle(context, int remainingCount, double leftPosition) {
    return Positioned(
      left: leftPosition,
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                imageUrls[4],
                cacheManager: ProfilePicturesCacheManager().instance,
                ),
              radius: 20,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            '+$remainingCount',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
        ),
      ),
    );
  }
}