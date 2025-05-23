import 'dart:convert';
import 'package:hive/hive.dart';

class CacheService {
  static const String CACHE_BOX = 'apiCacheBox';

  /// Default cache duration in minutes
  static const int DEFAULT_CACHE_DURATION = 30;

  /// Initialize the cache service
  static Future<void> init() async {
    await Hive.openBox(CACHE_BOX);
  }

  /// Get data from cache if available and not expired
  static dynamic getFromCache(String key) {
    try {
      final box = Hive.box(CACHE_BOX);
      final cacheData = box.get(key);

      if (cacheData == null) return null;

      final data = jsonDecode(cacheData['data']);
      final expiryTime = DateTime.parse(cacheData['expiryTime']);

      // Check if cache is still valid
      if (DateTime.now().isBefore(expiryTime)) {
        print('Getting data from cache for key: $key');
        return data;
      } else {
        print('Cache expired for key: $key');
        // Optionally remove expired cache
        box.delete(key);
        return null;
      }
    } catch (e) {
      print('Error getting data from cache: $e');
      return null;
    }
  }

  /// Save data to cache with expiry time
  static Future<void> saveToCache(String key, dynamic data,
      {int durationInMinutes = DEFAULT_CACHE_DURATION}) async {
    try {
      final box = Hive.box(CACHE_BOX);
      final expiryTime =
          DateTime.now().add(Duration(minutes: durationInMinutes));

      await box.put(key, {
        'data': jsonEncode(data),
        'expiryTime': expiryTime.toIso8601String(),
      });

      print('Data saved to cache with key: $key, expires at: $expiryTime');
    } catch (e) {
      print('Error saving data to cache: $e');
    }
  }

  /// Clear specific cache item
  static Future<void> clearCache(String key) async {
    try {
      final box = Hive.box(CACHE_BOX);
      await box.delete(key);
      print('Cache cleared for key: $key');
    } catch (e) {
      print('Error clearing cache for key: $key: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final box = Hive.box(CACHE_BOX);
      await box.clear();
      print('All cache cleared');
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// Clean expired cache entries
  static Future<void> cleanExpiredCache() async {
    try {
      final box = Hive.box(CACHE_BOX);
      final keys = box.keys.toList();

      for (final key in keys) {
        final cacheData = box.get(key);
        if (cacheData != null) {
          final expiryTime = DateTime.parse(cacheData['expiryTime']);
          if (DateTime.now().isAfter(expiryTime)) {
            await box.delete(key);
            print('Removed expired cache for key: $key');
          }
        }
      }
    } catch (e) {
      print('Error cleaning expired cache: $e');
    }
  }
}
