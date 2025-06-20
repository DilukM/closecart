import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class PreferencesService {
  static const String _apiBaseUrl =
      'https://closecart-backend.vercel.app/api/v1';
  static const String _categoriesCacheKey = 'userCategories';

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

  // Get user ID from JWT token
  static String? _getUserId() {
    var jwt = _getToken();
    if (jwt == null) return null;

    try {
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];
      if (userId != null && userId is String) {
        return userId;
      }
    } catch (e) {
      print('Error decoding JWT: $e');
    }
    return null;
  }

  // Get all available categories from the server
  static Future<List<String>> getAllCategories() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/categories');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   if (data['success']) {
      //     final List<dynamic> categoriesData = data['data'];
      //     return categoriesData
      //         .map((category) => category['name'].toString())
      //         .toList();
      //   }
      // }

      // Return default categories if API call fails
      return getDefaultCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      return getDefaultCategories();
    }
  }

  // Get user's preferred categories
  static Future<List<String>> getUserCategories() async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Try to get from cache first
    final cachedCategories = _getCachedCategories();
    if (cachedCategories.isNotEmpty) {
      return Future.value(cachedCategories);
    }

    try {
      final uri =
          Uri.parse('$_apiBaseUrl/consumer/interested-categories/$userId');
      final response = await http
          .get(
        uri,
        headers: _getAuthHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> categoriesData = data['data'];
          final categories =
              categoriesData.map((category) => category.toString()).toList();

          // Cache the results
          await _cacheCategories(categories);
          return categories;
        }
      }

      // Return default selected categories if API call fails
      return getDefaultSelectedCategories();
    } catch (e) {
      print('Error fetching user categories: $e');
      return getDefaultSelectedCategories();
    }
  }

  // Update user's preferred categories
  static Future<bool> updateUserCategories(List<String> categories) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final uri =
          Uri.parse('$_apiBaseUrl/consumer/interested-categories/$userId');
      final response = await http
          .put(
        uri,
        headers: _getAuthHeaders(),
        body: json.encode({'categories': categories}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Update the cache
          await _cacheCategories(categories);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating user categories: $e');
      // Still update the cache for offline use
      await _cacheCategories(categories);
      return false;
    }
  }

  // Get cached categories
  static List<String> _getCachedCategories() {
    final box = Hive.box('authBox');
    final List<dynamic>? cachedData = box.get(_categoriesCacheKey);

    if (cachedData == null) {
      return [];
    }

    try {
      return List<String>.from(cachedData);
    } catch (e) {
      print('Error parsing cached categories: $e');
      return [];
    }
  }

  // Save categories to cache
  static Future<void> _cacheCategories(List<String> categories) async {
    final box = Hive.box('authBox');
    await box.put(_categoriesCacheKey, categories);
  }

  // Default available categories if API fails - PUBLIC METHOD
  static List<String> getDefaultCategories() {
    return [
      "Food",
      "Retail",
      "Hotels & Accommodation",
      "Travel & Transport",
      "Banks",
      "Online",
      "Services",
      "Entertainment",
      "Health",
      "Beauty",
      "Electronics",
      "Fashion",
      "Other",
    ];
  }

  // Default selected categories if API fails - PUBLIC METHOD
  static List<String> getDefaultSelectedCategories() {
    return ['Food', 'Fashion', 'Tech'];
  }
}
