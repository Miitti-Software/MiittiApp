import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ProfilePicturesCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'ProfilePicturesCacheKey';
  static final ProfilePicturesCacheManager _instance = ProfilePicturesCacheManager._();
  
  factory ProfilePicturesCacheManager() => _instance;

  ProfilePicturesCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );

  Future<File> getProfileImage(String url, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    final response = await getImageFile(
      url,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
    ).firstWhere((response) => response is FileInfo);
    
    if (response is FileInfo) {
      return response.file;
    }
    throw Exception('Failed to get profile image');
  }
}

class MapTilesCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'MapTilesCacheKey';
  static final MapTilesCacheManager _instance = MapTilesCacheManager._();
  
  factory MapTilesCacheManager() => _instance;

  MapTilesCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 10000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );

  Future<File> getMapTile(String url, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    final response = await getImageFile(
      url,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
    ).firstWhere((response) => response is FileInfo);
    
    if (response is FileInfo) {
      return response.file;
    }
    throw Exception('Failed to get map tile');
  }
}
