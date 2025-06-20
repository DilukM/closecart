import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:closecart/models/shop_model.dart';
import 'package:closecart/services/location_service.dart';

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

  // Get device info
  static Future<String> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return 'Unknown Device';
  }

  // Get platform
  static String _getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    }
    return 'Unknown';
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

  /// Add shop click
  static Future<Map<String, dynamic>> addShopClick(String shopId) async {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get user ID from JWT
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Get location, device info, and platform
      UserLocation? userLocation;
      List<double>? position;

      try {
        userLocation = await LocationService.getCurrentLocation();
        position = [userLocation.longitude, userLocation.latitude];
      } catch (e) {
        print('Error getting location: $e');
        position = null;
      }

      final deviceInfo = await _getDeviceInfo();
      final platform = _getPlatform();

      final uri = Uri.parse('$_apiBaseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: json.encode({
          'userId': userId,
          'interactionType': "SHOP_CLICK",
          'targetType': "SHOP",
          'targetId': shopId,
          'action': "ADD",
          'metadata': {
            'location': position != null
                ? {
                    'type': "Point",
                    'coordinates': position,
                  }
                : null,
            'deviceInfo': deviceInfo,
            'platform': platform,
          },
        }),
      );

      final responseData = json.decode(response.body);
     

      if (response.statusCode == 200 && responseData['success']) {
        // Update local cache
        var shopClicks = box.get('shopClicks') ?? [];
        if (!shopClicks.contains(shopId)) {
          shopClicks.add(shopId);
          box.put('shopClicks', shopClicks);
        }

        return {
          'success': true,
          'message': 'Shop click added',
         
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to add clicked shop',
          
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        
      };
    }
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
      // Get location, device info, and platform
      UserLocation? userLocation;
      List<double>? position;

      try {
        userLocation = await LocationService.getCurrentLocation();
        position = [userLocation.longitude, userLocation.latitude];
      } catch (e) {
        print('Error getting location: $e');
        position = null;
      }

      final deviceInfo = await _getDeviceInfo();
      final platform = _getPlatform();

      final uri = Uri.parse('$_apiBaseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: _getAuthHeaders(),
        body: json.encode({
          'userId': userId,
          'interactionType': "SHOP_LIKE",
          'targetType': "SHOP",
          'targetId': shopId,
          'action': "ADD",
          'metadata': {
            'location': position != null
                ? {
                    'type': "Point",
                    'coordinates': position,
                  }
                : null,
            'deviceInfo': deviceInfo,
            'platform': platform,
          },
        }),
      );

      final responseData = json.decode(response.body);
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
      // Get location, device info, and platform
      UserLocation? userLocation;
      List<double>? position;

      try {
        userLocation = await LocationService.getCurrentLocation();
        position = [userLocation.longitude, userLocation.latitude];
      } catch (e) {
        print('Error getting location: $e');
        position = null;
      }

      final deviceInfo = await _getDeviceInfo();
      final platform = _getPlatform();

      final uri = Uri.parse('$_apiBaseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: _getAuthHeaders(),
        body: json.encode({
          'userId': userId,
          'interactionType': "SHOP_LIKE",
          'targetType': "SHOP",
          'targetId': shopId,
          'action': "REMOVE",
          'metadata': {
            'location': position != null
                ? {
                    'type': "Point",
                    'coordinates': position,
                  }
                : null,
            'deviceInfo': deviceInfo,
            'platform': platform,
          },
        }),
      );

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
