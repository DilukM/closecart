import 'package:closecart/models/shop_model.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopCacheService {
  static const String _shopCacheKey = 'shop_cache';
  static const String _shopCacheTimeKey = 'shop_cache_time';
  static const Duration _cacheValidDuration = Duration(hours: 24);
  static const String _baseUrl =
      "https://closecart-backend.vercel.app/api/v1/shops";

  /// Get a shop by its ID from cache
  static Shop? getShopById(String shopId) {
    try {
      final Map<String, Shop> shopMap = _getCachedShops();

      // Check if shop exists in cache
      if (shopMap.containsKey(shopId)) {
        return shopMap[shopId];
      }


      return null;
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

  /// Fetch a shop by ID from API
  static Future<Shop?> fetchShopById(String shopId) async {
    try {
      // First check if it's already in the cache
      Shop? cachedShop = getShopById(shopId);
      if (cachedShop != null) {
        return cachedShop;
      }

      // If not found in cache, try to refresh the entire shop catalog first
      final Map<String, Shop> refreshedShops = await prefetchAllShops();
      if (refreshedShops.containsKey(shopId)) {
        print('Found shop $shopId after refreshing the shop catalog');
        return refreshedShops[shopId];
      }

      // If still not found, try to fetch this specific shop
      final shopResponse = await http.get(Uri.parse("$_baseUrl/$shopId"));

      if (shopResponse.statusCode == 200) {
        final shopResponseData = jsonDecode(shopResponse.body);
        if (shopResponseData['shop'] != null) {
          final shop = Shop.fromJson(shopResponseData['shop']);

          // Update cache with this single shop
          final Map<String, Shop> existingShops = _getCachedShops();
          existingShops[shopId] = shop;

          // Convert shops to JSON format for storage
          final Map<String, dynamic> shopDataToCache = {};
          existingShops.forEach((key, shop) {
            shopDataToCache[key] = shop.toJson();
          });

          // Save to cache
          var box = Hive.box('authBox');
          await box.put(_shopCacheKey, jsonEncode(shopDataToCache));

          return shop;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching shop details for $shopId: $e');
      return null;
    }
  }

  /// Prefetch all shops and cache them
  static Future<Map<String, Shop>> prefetchAllShops() async {
    try {
      final Map<String, Shop> shopCache = _getCachedShops();

      // If we already have cached shops and cache is valid, return them
      // if (shopCache.isNotEmpty && isCacheValid()) {
      //   print('Using ${shopCache.length} shops from cache');
      //   return shopCache;
      // }

      // Otherwise fetch from API
      final shopsResponse = await http.get(Uri.parse("$_baseUrl/"));

      if (shopsResponse.statusCode == 200) {
        final shopsData = jsonDecode(shopsResponse.body);
        final Map<String, Shop> newShopCache = {};

        if (shopsData['data'] != null && shopsData['data'] is List) {
          for (var shopData in shopsData['data']) {
            final shop = Shop.fromJson(shopData);
            newShopCache[shop.id] = shop;
          }

          // Cache the fetched shops
          await cacheShops(newShopCache.values.toList());
          return newShopCache;
        }
      }

      // Return empty map if fetch failed
      return {};
    } catch (e) {
      print('Error prefetching shops: $e');
      return {};
    }
  }
}
