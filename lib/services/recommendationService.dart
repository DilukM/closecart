import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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
        print("Found cached recommendations for key: $cacheKey");
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

      print('Fetching recommendations from: $uri');

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
}
