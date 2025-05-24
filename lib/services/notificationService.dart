import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:closecart/model/notificationModel.dart';

class NotificationService {
  static const String _apiBaseUrl =
      'https://closecart-backend.vercel.app/api/v1';
  static const String _cacheKey = 'userNotifications';

  // Flag to use mocked data during development
  static bool useMockedData = false;

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

  // Get cached notifications
  static List<NotificationModel> getCachedNotifications() {
    final box = Hive.box('authBox');
    final List<dynamic>? cachedData = box.get(_cacheKey);

    if (cachedData == null) {
      return [];
    }

    try {
      return List<NotificationModel>.from(
          cachedData.map((json) => NotificationModel.fromJson(json)));
    } catch (e) {
      print('Error parsing cached notifications: $e');
      return [];
    }
  }

  // Save notifications to cache
  static Future<void> _cacheNotifications(
      List<NotificationModel> notifications) async {
    final box = Hive.box('authBox');
    await box.put(_cacheKey, notifications.map((n) => n.toJson()).toList());
  }

  // Fetch notifications from API
  static Future<List<NotificationModel>> fetchNotifications(
      {bool backgroundRefresh = false}) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // First try to get cached data
    final cachedNotifications = getCachedNotifications();

    try {
      final uri = Uri.parse('$_apiBaseUrl/notifications/user/$userId');

      // Try to make API call with timeout
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
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          final List<dynamic> notificationsData = responseData['data'];
          final notifications = notificationsData
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          // Cache the results
          await _cacheNotifications(notifications);

          return notifications;
        } else {
          print('API returned error: ${responseData['message']}');
          // Return cached data if available, otherwise throw error
          if (cachedNotifications.isNotEmpty && backgroundRefresh) {
            return cachedNotifications;
          }
          throw Exception(
              responseData['message'] ?? 'Failed to fetch notifications');
        }
      } else if (response.statusCode == 404) {
        print(
            'Notification API endpoint not found (404). The endpoint may not be implemented yet.');

        // Return existing cached data if this is a background refresh
        if (backgroundRefresh && cachedNotifications.isNotEmpty) {
          return cachedNotifications;
        }

        throw Exception(
            'Notification service endpoint not available. Using cached data if available.');
      } else {
        print('HTTP error ${response.statusCode} when fetching notifications');

        // Return cached data if available for non-200 status
        if (cachedNotifications.isNotEmpty && backgroundRefresh) {
          return cachedNotifications;
        }
        throw Exception(
            'Failed to fetch notifications: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');

      if (backgroundRefresh && cachedNotifications.isNotEmpty) {
        // If it's a background refresh and we have cached data, return it
        return cachedNotifications;
      }

      if (cachedNotifications.isNotEmpty) {
        return cachedNotifications;
      }

      rethrow;
    }
  }

  // Helper to generate API links based on notification type
  static String _generateLink(NotificationType type, String id) {
    switch (type) {
      case NotificationType.offer:
        return '/offers/$id';
      case NotificationType.shop:
        return '/shops/$id';
      case NotificationType.order:
        return '/orders/$id';
      case NotificationType.info:
        return '/tips/$id';
      case NotificationType.error:
        return '/errors/$id';
      case NotificationType.system:
      default:
        return '/notifications';
    }
  }

  // Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/notifications/$notificationId/read');
      final response = await http.patch(
        uri,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Update the cached notification
          final notifications = getCachedNotifications();
          final updatedNotifications = notifications.map((notification) {
            if (notification.id == notificationId) {
              return notification.copyWith(isRead: true);
            }
            return notification;
          }).toList();

          await _cacheNotifications(updatedNotifications);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/notifications/user/$userId/read-all');
      final response = await http.patch(
        uri,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Update all cached notifications
          final notifications = getCachedNotifications();
          final updatedNotifications =
              notifications.map((n) => n.copyWith(isRead: true)).toList();

          await _cacheNotifications(updatedNotifications);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/notifications/$notificationId');
      final response = await http.delete(
        uri,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Update the cached notifications
          final notifications = getCachedNotifications();
          final updatedNotifications = notifications
              .where((notification) => notification.id != notificationId)
              .toList();

          await _cacheNotifications(updatedNotifications);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Get unread notification count
  static int getUnreadCount() {
    final notifications = getCachedNotifications();
    return notifications.where((n) => !n.isRead).length;
  }
}
