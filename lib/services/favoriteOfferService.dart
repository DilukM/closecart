import 'dart:convert';
import 'dart:io';
import 'package:closecart/services/location_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/offer_model.dart'; // Add this import

class FavoriteOfferService {
  static const String baseUrl = "https://closecart-backend.vercel.app/api/v1";
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
      // Return a default value instead of null
      return 'Unknown Device';
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

  /// Check if offer can be clicked (6-hour cooldown)
  static bool canClickOffer(String offerId) {
    try {
      var box = Hive.box('authBox');
      var offerClickTimestamps =
          box.get('offerClickTimestamps') ?? <String, int>{};

      // Convert to Map<String, int> if needed
      Map<String, int> clickTimestamps =
          Map<String, int>.from(offerClickTimestamps);

      if (!clickTimestamps.containsKey(offerId)) {
        return true; // Never clicked before
      }

      int lastClickTime = clickTimestamps[offerId]!;
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      int sixHoursInMs = 6 * 60 * 60 * 1000; // 6 hours in milliseconds

      return (currentTime - lastClickTime) >= sixHoursInMs;
    } catch (e) {
      print('Error checking offer click cooldown: $e');
      return true; // Default to allowing click on error
    }
  }

  /// Record offer click timestamp
  static void recordOfferClick(String offerId) {
    try {
      var box = Hive.box('authBox');
      var offerClickTimestamps =
          box.get('offerClickTimestamps') ?? <String, int>{};

      // Convert to Map<String, int> if needed
      Map<String, int> clickTimestamps =
          Map<String, int>.from(offerClickTimestamps);
      clickTimestamps[offerId] = DateTime.now().millisecondsSinceEpoch;

      box.put('offerClickTimestamps', clickTimestamps);
    } catch (e) {
      print('Error recording offer click timestamp: $e');
    }
  }

  /// Add offer click
  static Future<Map<String, dynamic>> addOfferClick(String offerId) async {
    // Check cooldown first
    if (!canClickOffer(offerId)) {
      return {
        'success': false,
        'message': 'Offer click is on cooldown (6 hours)',
        'onCooldown': true,
      };
    }
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

      final uri = Uri.parse('$baseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: json.encode({
          'userId': userId,
          'interactionType': "OFFER_CLICK",
          'targetType': "OFFER",
          'targetId': offerId,
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
        // Record the click timestamp for cooldown
        recordOfferClick(offerId);

        // Update local cache
        var offerClicks = box.get('offerClicks') ?? [];
        if (!offerClicks.contains(offerId)) {
          offerClicks.add(offerId);
          box.put('offerClicks', offerClicks);
        }

        return {
          'success': true,
          'message': 'Offer click added',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add clicked offer',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Add offer to favorites
  static Future<Map<String, dynamic>> addToFavorites(String offerId) async {
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

      final uri = Uri.parse('$baseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: json.encode({
          'userId': userId,
          'interactionType': "OFFER_LIKE",
          'targetType': "OFFER",
          'targetId': offerId,
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
        var favorites = box.get('favorites') ?? [];
        if (!favorites.contains(offerId)) {
          favorites.add(offerId);
          box.put('favorites', favorites);
        }

        // Clear cached favorite offers to force refresh
        box.delete('favoriteOffers');

        return {
          'success': true,
          'message': 'Offer added to favorites',
          'isFavorite': true,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to add offer to favorites',
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

  /// Remove offer from favorites
  static Future<Map<String, dynamic>> removeFromFavorites(
      String offerId) async {
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

      final uri = Uri.parse('$baseUrl/interactions/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: json.encode({
          'userId': userId,
          'interactionType': "OFFER_LIKE",
          'targetType': "OFFER",
          'targetId': offerId,
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
        // Update local cache
        var favorites = box.get('favorites') ?? [];
        favorites.remove(offerId);
        box.put('favorites', favorites);

        // Clear cached favorite offers to force refresh
        box.delete('favoriteOffers');

        return {
          'success': true,
          'message': 'Offer removed from favorites',
          'isFavorite': false,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Failed to remove offer from favorites',
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

  /// Toggle favorite status (add or remove from favorites)
  static Future<Map<String, dynamic>> toggleFavorite(String offerId) async {
    // Check if offer is already in favorites locally
    var box = Hive.box('authBox');
    var favorites = box.get('favorites') ?? [];
    bool isAlreadyFavorite = favorites.contains(offerId);

    if (isAlreadyFavorite) {
      return await removeFromFavorites(offerId);
    } else {
      return await addToFavorites(offerId);
    }
  }

  /// Check if an offer is in favorites
  static bool isFavorite(String offerId) {
    try {
      var box = Hive.box('authBox');
      var favorites = box.get('favorites') ?? [];
      return favorites.contains(offerId);
    } catch (error) {
      print('Error checking favorite status: $error');
      return false;
    }
  }

  /// Fetch all favorites from the server and update local cache
  static Future<List<String>> fetchFavorites() async {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception('Authentication token not found');
      }

      // Get user ID from JWT
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Make API request
      final response = await http.get(
        Uri.parse('$baseUrl/consumer/liked-offers/$userId'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract favorite offers from the response
        // Check if data is a list directly or nested within an object
        List<dynamic> offersData;
        if (data is List) {
          offersData = data;
        } else if (data is Map) {
          // Try different possible keys where the favorites might be stored
          if (data.containsKey('data')) {
            offersData = data['data'] is List ? data['data'] : [];
          } else if (data.containsKey('favorites')) {
            offersData = data['favorites'] is List ? data['favorites'] : [];
          } else if (data.containsKey('likedOffers')) {
            offersData = data['likedOffers'] is List ? data['likedOffers'] : [];
          } else {
            // If none of the expected keys exist, look for the first list in the response
            offersData = data.values
                .firstWhere((value) => value is List, orElse: () => []);
          }
        } else {
          offersData = [];
        }

        // Extract offer IDs from the offers data
        List<String> favoriteIds = [];
        for (var offer in offersData) {
          if (offer is Map && offer.containsKey('_id')) {
            favoriteIds.add(offer['_id'].toString());
          } else if (offer is String) {
            favoriteIds.add(offer);
          }
        }

        print("Extracted favorite IDs: $favoriteIds");

        // Update local cache
        box.put('favorites', favoriteIds);
        return favoriteIds;
      } else {
        // Return cached favorites on error
        return box.get('favorites') ?? [];
      }
    } catch (error) {
      print('Error fetching favorites: $error');
      // Return cached favorites on error
      var box = Hive.box('authBox');
      return box.get('favorites') ?? [];
    }
  }

  /// Get cached favorites immediately
  static List<Map<String, dynamic>> getCachedFavoriteOffers() {
    try {
      var box = Hive.box('authBox');

      // Try to get cached favorite offers first
      final cachedOffers = box.get('favoriteOffers');
      if (cachedOffers != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedOffers)
            .map((item) => Map<String, dynamic>.from(item)));
      }

      // If no cached offers data, try to build from favorite IDs
      var favoriteIds = box.get('favorites') ?? [];
      if (favoriteIds.isNotEmpty) {
        return List<String>.from(favoriteIds)
            .map((id) => {
                  '_id': id,
                  'title': 'Favorite Offer',
                  'imageUrl':
                      'https://www.foodiesfeed.com/wp-content/uploads/2023/06/burger-with-melted-cheese.jpg',
                  'rating': 4.0,
                })
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting cached favorites: $e');
      return [];
    }
  }

  /// Fetch all favorites with offer details, with support for background refresh
  static Future<List<Offer>> fetchFavoriteOffers(
      {bool backgroundRefresh = false}) async {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception('Authentication token not found');
      }

      // Get user ID from JWT
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Make API request
      final response = await http.get(
        Uri.parse('$baseUrl/consumer/liked-offers/$userId'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract offers from the response with flexible parsing
        List<dynamic> offerData = [];

        if (responseData is List) {
          offerData = responseData;
        } else if (responseData is Map) {
          // Try different possible keys where the favorites might be stored
          if (responseData.containsKey('data')) {
            offerData =
                responseData['data'] is List ? responseData['data'] : [];
          } else if (responseData.containsKey('favorites')) {
            offerData = responseData['favorites'] is List
                ? responseData['favorites']
                : [];
          } else if (responseData.containsKey('likedOffers')) {
            offerData = responseData['likedOffers'] is List
                ? responseData['likedOffers']
                : [];
          } else {
            // If none of the expected keys exist, look for the first list in the response
            offerData = responseData.values
                .firstWhere((value) => value is List, orElse: () => []);
          }
        }

        if (offerData.isNotEmpty) {
          List<String> favoriteIds = [];

          // Convert each offer to Offer object
          List<Offer> offers = offerData.map<Offer>((offerJson) {
            String offerId = offerJson['_id']?.toString() ?? '';
            favoriteIds.add(offerId);
            return Offer.fromJson(offerJson);
          }).toList();

          // Update favorite IDs in cache
          box.put('favorites', favoriteIds);

          // Cache the raw data for future use
          box.put('favoriteOffers', jsonEncode(offerData));

          print("Fetched ${offers.length} favorite offers");
          return offers;
        }

        // Return empty list if no offer data found
        return [];
      } else {
        // Return cached data on error
        return _getCachedFavoriteOffers();
      }
    } catch (error) {
      print('Error fetching favorite offers: $error');
      return _getCachedFavoriteOffers();
    }
  }

  /// Get cached favorites immediately as Offer objects
  static List<Offer> _getCachedFavoriteOffers() {
    try {
      var box = Hive.box('authBox');

      // Try to get cached favorite offers first
      final cachedOffers = box.get('favoriteOffers');
      if (cachedOffers != null) {
        List<dynamic> offersJson = jsonDecode(cachedOffers);
        return offersJson.map<Offer>((json) => Offer.fromJson(json)).toList();
      }

      // If no cached offers data, return empty list
      return [];
    } catch (e) {
      print('Error getting cached favorites: $e');
      return [];
    }
  }
}
