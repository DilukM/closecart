import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:closecart/model/shopModel.dart';

class FavoriteShopService {
  static const String _apiBaseUrl =
      'https://closecart-backend.vercel.app/api/v1';
  static const String _cacheKey = 'favoriteShops';

  // Get JWT token from local storage
  static String? _getToken() {
    final box = Hive.box('authBox');
    return box.get('jwtToken');
  }

  // Get headers with authorization
  static Map<String, String> _getAuthHeaders() {
    final token = _getToken();
    print("token: $token");

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get user ID from local storage
  static String? _getUserId() {
    var box = Hive.box('authBox');
    var jwt = box.get('jwtToken');

    if (jwt == null) {
      throw Exception('Authentication token not found');
    }

    // Get user ID from JWT
    final jwtToken = JWT.decode(jwt);
    final userId = jwtToken.payload['id'];
    if (userId != null && userId is String) {
      return userId;
    }
    return null;
  }

  // Check if a shop is already in favorites
  static bool isFavorite(String shopId) {
    final box = Hive.box('authBox');
    final List<dynamic>? cachedShops = box.get(_cacheKey);

    if (cachedShops == null || cachedShops.isEmpty) {
      return false;
    }

    return cachedShops.any((shop) => shop is Map && shop['_id'] == shopId);
  }

  // Get cached favorite shops
  static List<Map<String, dynamic>> getCachedFavoriteShops() {
    final box = Hive.box('authBox');
    final List<dynamic>? cachedShops = box.get(_cacheKey);

    if (cachedShops == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
        cachedShops.map((shop) => shop as Map<String, dynamic>));
  }

  // Fetch favorite shops from API
  static Future<List<Shop>> fetchFavoriteShops(
      {bool backgroundRefresh = false}) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/consumer/liked-shops/$userId');
      final response = await http.get(
        uri,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          final List<dynamic> shopsData = responseData['data'];
          final List<Map<String, dynamic>> shops =
              shopsData.map((shop) => shop as Map<String, dynamic>).toList();

          // Cache the results
          final box = Hive.box('authBox');
          box.put(_cacheKey, shops);

          // Convert to Shop objects
          return shops.map((shop) => Shop.fromJson(shop)).toList();
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch favorite shops');
        }
      } else {
        throw Exception(
            'Failed to fetch favorite shops: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!backgroundRefresh) {
        // Only rethrow the error if this isn't a background refresh
        rethrow;
      }
      // Return cached data for background refreshes that fail
      return getCachedFavoriteShops()
          .map((shop) => Shop.fromJson(shop))
          .toList();
    }
  }

  // Add shop to favorites
  static Future<Map<String, dynamic>> addToFavorites(String shopId) async {
    final userId = _getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/consumer/liked-shops');
      final response = await http.post(
        uri,
        headers: _getAuthHeaders(),
        body: json.encode({
          'userId': userId,
          'shopId': shopId,
        }),
      );

      final responseData = json.decode(response.body);
      print("responseData: $responseData");
      if (response.statusCode == 200 && responseData['success']) {
        // Update cache
        await fetchFavoriteShops(backgroundRefresh: true);

        return {
          'success': true,
          'message': 'Shop added to favorites',
          'isFavorite': true,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to add shop to favorites',
          'isFavorite': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'isFavorite': false,
      };
    }
  }

  // Remove shop from favorites
  static Future<Map<String, dynamic>> removeFromFavorites(String shopId) async {
    final userId = _getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/consumer/liked-shops');

      // For DELETE with body, we need to use a special method
      final request = http.Request('DELETE', uri);

      // Add authorization headers
      final headers = _getAuthHeaders();
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      request.body = json.encode({
        'userId': userId,
        'shopId': shopId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Update cache
        await fetchFavoriteShops(backgroundRefresh: true);

        return {
          'success': true,
          'message': 'Shop removed from favorites',
          'isFavorite': false,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to remove shop from favorites',
          'isFavorite': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'isFavorite': true,
      };
    }
  }

  // Toggle favorite status (add or remove)
  static Future<Map<String, dynamic>> toggleFavorite(String shopId) async {
    if (isFavorite(shopId)) {
      return removeFromFavorites(shopId);
    } else {
      return addToFavorites(shopId);
    }
  }
}
