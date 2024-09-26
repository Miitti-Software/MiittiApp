import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ProfilePicturesCacheManager {
  static final ProfilePicturesCacheManager _instance = ProfilePicturesCacheManager._internal();
  factory ProfilePicturesCacheManager() => _instance;
  ProfilePicturesCacheManager._internal();

  final CacheManager instance = CacheManager(
    Config(
      'ProfilePicturesCacheKey',
      stalePeriod: const Duration(seconds: 10),
      maxNrOfCacheObjects: 1000,
    ),
  );
}

class MapTilesCacheManager {
  static final MapTilesCacheManager _instance = MapTilesCacheManager._internal();
  factory MapTilesCacheManager() => _instance;
  MapTilesCacheManager._internal();

  final CacheManager instance = CacheManager(
    Config(
      'MapTilesCacheKey',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 10000,
    ),
  );
}
