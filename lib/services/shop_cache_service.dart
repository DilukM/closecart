import 'package:closecart/model/shopModel.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class ShopCacheService {
  static const String _shopCacheKey = 'shop_cache';
  static const String _shopCacheTimeKey = 'shop_cache_time';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// Get a shop by its ID from cache
  static Shop? getShopById(String shopId) {
    try {
      final Map<String, Shop> shopMap = _getCachedShops();
      return shopMap[shopId];
    } catch (e) {
      print('Error getting shop by ID: $e');
      return null;
    }
  }

  /// Get all shops from cache
  static Map<String, Shop> _getCachedShops() {
    try {
      var box = Hive.box('authBox');
      final cachedData = box.get(_shopCacheKey);

      if (cachedData != null) {
        final shopData = jsonDecode(cachedData) as Map<String, dynamic>;
        final Map<String, Shop> shops = {};

        shopData.forEach((key, value) {
          shops[key] = Shop.fromJson(value);
        });

        return shops;
      }

      return {};
    } catch (e) {
      print('Error getting cached shops: $e');
      return {};
    }
  }

  /// Cache shops data
  static Future<void> cacheShops(List<Shop> shops) async {
    try {
      var box = Hive.box('authBox');

      final Map<String, dynamic> shopData = {};
      for (var shop in shops) {
        shopData[shop.id] = shop.toJson();
      }

      await box.put(_shopCacheKey, jsonEncode(shopData));
      await box.put(_shopCacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching shops: $e');
    }
  }

  /// Check if the shop cache is valid
  static bool isCacheValid() {
    try {
      var box = Hive.box('authBox');
      final cacheTimeStr = box.get(_shopCacheTimeKey);

      if (cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final now = DateTime.now();
        return now.difference(cacheTime) <= _cacheValidDuration;
      }

      return false;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Get shop name by ID, with fallback
  static String getShopNameById(String shopId,
      {String fallback = 'Unknown Store'}) {
    final shop = getShopById(shopId);
    return shop?.name ?? fallback;
  }
}
