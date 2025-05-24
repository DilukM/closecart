import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:closecart/services/geofence_service.dart';
import 'package:closecart/services/shop_cache_service.dart';
import 'package:closecart/model/shopModel.dart';

class RecommendationService {
  static const String baseUrl =
      "https://kmeans-ggnx.onrender.com/cluster_recommend";

  /// Get cached recommendations for immediate display
  static Map<String, dynamic> getCachedRecommendations({String? city}) {
    try {
      var box = Hive.box('authBox');
      final userId = _getUserIdFromToken();

      if (userId == null) {
        print("User ID not found in token");
        return {'success': false, 'message': 'User ID not available'};
      }

      // Create a cache key based on the userId and city
      final String cacheKey = 'recommendations_${userId}_${city ?? "all"}';
      final cachedData = box.get(cacheKey);

      if (cachedData != null) {
        return {
          'success': true,
          'recommendations': jsonDecode(cachedData),
          'fromCache': true,
        };
      } else {
        print("No cached data found for key: $cacheKey");

        // Try to get any recommendations cache as fallback
        final keys = box.keys
            .where((k) => k.toString().startsWith('recommendations_'))
            .toList();
        if (keys.isNotEmpty) {
          final fallbackData = box.get(keys.first);
          if (fallbackData != null) {
            print("Using fallback cache from: ${keys.first}");
            return {
              'success': true,
              'recommendations': jsonDecode(fallbackData),
              'fromCache': true,
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'No cached recommendations available'
      };
    } catch (e) {
      print('Error getting cached recommendations: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Helper method to get user ID from token
  static String? _getUserIdFromToken() {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) return null;

      final jwtToken = JWT.decode(jwt);
      return jwtToken.payload['id'];
    } catch (e) {
      print('Error extracting user ID: $e');
      return null;
    }
  }

  /// Fetches recommendations based on user ID and city
  static Future<Map<String, dynamic>> getRecommendations(
      {String? city,
      bool forceRefresh = false,
      bool backgroundRefresh = false}) async {
    try {
      // Get user ID from stored JWT
      var userId = _getUserIdFromToken();

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      // Create a cache key based on the userId and city
      final String cacheKey = 'recommendations_${userId}_${city ?? "all"}';

      // If not forcing refresh and not background refresh, try to get data from cache
      if (!forceRefresh && !backgroundRefresh) {
        final cachedResult = getCachedRecommendations(city: city);
        if (cachedResult['success'] == true) {
          return cachedResult;
        }
      }

      // Build URL with parameters
      final Uri uri = city != null && city.isNotEmpty
          ? Uri.parse('$baseUrl/$userId?city=$city')
          : Uri.parse('$baseUrl/$userId');

      // Make API request
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Convert the response to a list of offers
        List<dynamic> recommendedOffers = [];
        if (data is List) {
          recommendedOffers = data;
        } else if (data is Map && data.containsKey('recommendations')) {
          recommendedOffers = data['recommendations'] as List;
        }

        // Extract shop data from offers and cache it
        _extractAndCacheShopData(recommendedOffers);

        // Save to cache
        var box = Hive.box('authBox');
        box.put(cacheKey, jsonEncode(recommendedOffers));

        return {
          'success': true,
          'recommendations': recommendedOffers,
          'fromCache': false,
        };
      } else {
        // If background refresh failed, don't report error
        if (backgroundRefresh) {
          return getCachedRecommendations(city: city);
        }

        return {
          'success': false,
          'message':
              'Failed to fetch recommendations. Status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('Error fetching recommendations: $error');

      // Return cached data if available when error occurs
      if (backgroundRefresh) {
        return getCachedRecommendations(city: city);
      }

      return {'success': false, 'message': 'Error: ${error.toString()}'};
    }
  }

  /// Extract shop data from offers and cache it
  static void _extractAndCacheShopData(List<dynamic> offers) {
    try {
      List<Shop> shops = [];

      for (var offer in offers) {
        if (offer is Map<String, dynamic> &&
            offer.containsKey('shop') &&
            offer['shop'] != null) {
          // If the offer has complete shop data
          shops.add(Shop.fromJson(offer['shop']));
        } else if (offer is Map<String, dynamic> &&
            offer.containsKey('shopId') &&
            offer['shopId'] != null &&
            offer.containsKey('storeName')) {
          // If the offer only has basic shop info
          Shop basicShop = Shop(
            id: offer['shopId'].toString(),
            name: offer['storeName'].toString(),
            address: offer['address']?.toString() ?? '',
            category: offer['category']?.toString() ?? 'Other',
            location: Location(coordinates: [
              double.tryParse(offer['longitude'].toString()) ?? 0.0,
              double.tryParse(offer['latitude'].toString()) ?? 0.0,
            ]),
          );

          shops.add(basicShop);
        }
      }

      if (shops.isNotEmpty) {
        ShopCacheService.cacheShops(shops);
      }
    } catch (e) {
      print('Error extracting and caching shop data: $e');
    }
  }

  /// Get offers filtered by current geofence
  static Future<Map<String, dynamic>> getOffersInGeofence(
      {required GeofenceService geofenceService,
      String? city,
      bool forceRefresh = false}) async {
    try {
      // Get all recommendations
      final recommendationsResult = await getRecommendations(
        city: city,
        forceRefresh: forceRefresh,
      );

      if (recommendationsResult['success'] != true) {
        return recommendationsResult;
      }

      List<dynamic> allOffers = recommendationsResult['recommendations'];

      // If no geofence is set, return all offers
      if (geofenceService.currentGeofence == null) {
        return recommendationsResult;
      }

      // Fetch all shops - useful for bulk processing
      final Map<String, Shop> shopCache = {};

      // Pre-fetch all shops for better performance
      try {
        final shopsResponse = await http.get(
            Uri.parse("https://closecart-backend.vercel.app/api/v1/shops/"));

        if (shopsResponse.statusCode == 200) {
          final shopsData = jsonDecode(shopsResponse.body);
          if (shopsData['data'] != null && shopsData['data'] is List) {
            for (var shopData in shopsData['data']) {
              final shop = Shop.fromJson(shopData);
              shopCache[shop.id] = shop;
            }
            print('Prefetched ${shopCache.length} shops');
          }
        }
      } catch (e) {
        print('Error prefetching shops: $e');
        // Continue with individual fetches if bulk fetch fails
      }

      // Filter offers that are within the current geofence
      List<dynamic> filteredOffers = [];

      for (var offer in allOffers) {
        if (!(offer is Map<String, dynamic>)) continue;

        // Get the shop ID from the offer
        String? shopId;
        if (offer.containsKey('shop') && offer['shop'] != null) {
          // Handle when shop is a string ID
          if (offer['shop'] is String) {
            shopId = offer['shop'];
          }
          // Handle when shop is an object with _id
          else if (offer['shop'] is Map && offer['shop'].containsKey('_id')) {
            shopId = offer['shop']['_id'];
          }
        }

        if (shopId == null) continue;

        // Try to get shop from cache or fetch individually
        Shop? shop = shopCache[shopId];

        // If not in cache, fetch the shop details
        if (shop == null) {
          try {
            final shopResponse = await http.get(Uri.parse(
                "https://closecart-backend.vercel.app/api/v1/shops/$shopId"));

            if (shopResponse.statusCode == 200) {
              final shopData = jsonDecode(shopResponse.body);
              if (shopData['shop'] != null) {
                shop = Shop.fromJson(shopData['shop']);
                shopCache[shopId] = shop; // Add to cache
              }
            }
          } catch (e) {
            print('Error fetching shop details for $shopId: $e');
            continue;
          }
        }

        // Check if the shop's location is within the geofence
        if (shop != null) {
          final longitude = shop.location.longitude;
          final latitude = shop.location.latitude;

          // Check if the shop's location is valid
          if (longitude != 0.0 || latitude != 0.0) {
            if (geofenceService.isLocationInCurrentGeofence(
                latitude, longitude)) {
              // Add shop and location details to the offer for display
              final offerWithLocation = Map<String, dynamic>.from(offer);
              offerWithLocation['shopDetails'] = {
                'name': shop.name,
                'address': shop.address,
                'longitude': longitude,
                'latitude': latitude,
                'isOpenNow': shop.isOpenNow,
                'openingStatus': shop.openingStatusText
              };

              filteredOffers.add(offerWithLocation);
            }
          }
        }
      }

      return {
        'success': true,
        'recommendations': filteredOffers,
        'fromCache': recommendationsResult['fromCache'] ?? false,
        'filtered': true,
        'shopsFound': shopCache.length,
      };
    } catch (e) {
      print('Error filtering offers by geofence: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
