import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../model/offerModel.dart'; // Add this import

class FavoriteOfferService {
  static const String baseUrl =
      "https://closecart-backend.vercel.app/api/v1/consumer/liked-offers";

  /// Toggle favorite status (add or remove from favorites)
  static Future<Map<String, dynamic>> toggleFavorite(String offerId) async {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception('Authentication token not found');
      }

      // Get user ID from JWT
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Check if offer is already in favorites locally
      var favorites = box.get('favorites') ?? [];
      bool isAlreadyFavorite = favorites.contains(offerId);

      // Make API request based on current favorite status
      http.Response response;

      if (isAlreadyFavorite) {
        // DELETE request with proper format for axios-like clients
        final deleteUrl = Uri.parse(baseUrl);
        response = await http.delete(
          deleteUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({
            'userId': userId,
            'offerId': offerId,
          }),
        );
      } else {
        // POST request to add to favorites
        final postUrl = Uri.parse(baseUrl);
        response = await http.post(
          postUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({
            'userId': userId,
            'offerId': offerId,
          }),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Update local cache
        if (isAlreadyFavorite) {
          favorites.remove(offerId);
        } else {
          favorites.add(offerId);
        }
        box.put('favorites', favorites);

        return {
          'success': true,
          'isFavorite': !isAlreadyFavorite,
          'message': isAlreadyFavorite
              ? 'Removed from favorites'
              : 'Added to favorites'
        };
      } else {
        print('Failed to toggle favorite: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update favorites'
        };
      }
    } catch (error) {
      print('Error toggling favorite: $error');
      return {'success': false, 'message': error.toString()};
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
      print("userId: $userId");

      // Make API request
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );
      print(response.body);

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
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract offers from the response
        if (responseData is Map && responseData.containsKey('data')) {
          List<dynamic> offerData = responseData['data'];
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

          return offers;
        }

        // Return empty list if data structure is unexpected
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
