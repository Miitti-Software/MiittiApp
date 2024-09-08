import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final CustomCacheManager _instance = CustomCacheManager._internal();
  factory CustomCacheManager() => _instance;
  CustomCacheManager._internal();

  final CacheManager instance = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(seconds: 1),
      maxNrOfCacheObjects: 1000,
    ),
  );
}
