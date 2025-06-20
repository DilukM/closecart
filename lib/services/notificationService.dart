import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:closecart/models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Provider to track notification permissions
class NotificationPermissionProvider with ChangeNotifier {
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  set permissionGranted(bool value) {
    _permissionGranted = value;
    notifyListeners();
  }
}

class NotificationService {
  static const String _apiBaseUrl =
      'https://closecart-backend.vercel.app/api/v1';
  static const String _cacheKey = 'userNotifications';

  // Flag to use mocked data during development
  static bool useMockedData = false;

  // FlutterLocalNotificationsPlugin instance
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Permission status storage key
  static const String _permissionKey = 'notificationPermissionStatus';

  // Initialize the notification plugin
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false, // We'll request manually
      requestSoundPermission: false, // We'll request manually
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Handle notification taps here
        print('Notification clicked: ${notificationResponse.payload}');
      },
    );

    // Request permissions after initialization
    await requestNotificationPermissions();
  }

  // Request notification permissions explicitly
  static Future<bool> requestNotificationPermissions() async {
    // Always check current status first
    final currentStatus = await checkCurrentPermissionStatus();

    // If already granted, just return true
    if (currentStatus) {
      return true;
    }

    // Otherwise try to request permissions
    try {
      final granted = await _requestPermissions();

      // Save the updated status
      final box = Hive.box('authBox');
      await box.put(_permissionKey, granted);

      return granted;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Check the current actual permission status (not from cache)
  static Future<bool> checkCurrentPermissionStatus() async {
    try {
      // On Android
      final androidImplementation =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final areEnabled =
            await androidImplementation.areNotificationsEnabled();
        return areEnabled ?? false;
      }

      // On iOS
      final iOSImplementation =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iOSImplementation != null) {
        // For iOS, we don't have a direct way to check, so we'll request permissions
        // which will tell us the current status
        final isGranted = await iOSImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return isGranted ?? false;
      }

      // Default case if platform-specific implementation not available
      return false;
    } catch (e) {
      print('Error checking notification permission status: $e');
      return false;
    }
  }

  // Check if notifications are supported
  static Future<bool> _areNotificationsSupported() async {
    try {
      return await notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          true; // Default to true for iOS or if check fails
    } catch (e) {
      print("Error checking notification support: $e");
      return true; // Default to true if error
    }
  }

  // Request permissions on the platform
  static Future<bool> _requestPermissions() async {
    // For Android 13+
    final androidImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final result =
          await androidImplementation.requestNotificationsPermission();
      return result ?? false;
    }

    // For iOS
    final iOSImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iOSImplementation != null) {
      return await iOSImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  // Open app notification settings
  static Future<void> openNotificationSettings() async {
    try {
      // For Android
      final androidImplementation =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await AppSettings.openAppSettings(
          type: AppSettingsType.notification,
        );
        return;
      }

      // For iOS, we need to guide users to settings manually
      throw Exception('Cannot open settings directly on this platform');
    } catch (e) {
      print('Error opening notification settings: $e');
      // When direct settings access fails, show instructions to the user
      // The UI will handle displaying instructions to manually open settings
    }
  }

  // Show local push notification
  static Future<void> showLocalPushNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    print("showLocalPushNotification running");

    // Check permission first
    if (!await _areNotificationsSupported()) {
      print("Notifications not permitted. Skipping notification.");
      return;
    }

    // Android notification details with explicit icon resource
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'closecart_notifications',
      'CloseCart Notifications',
      channelDescription: 'Notifications from CloseCart app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    print("Notification details configured.");

    try {
      // Use a unique ID for each notification - millisecond wasn't unique enough
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await notificationsPlugin.show(
        notificationId,
        title,
        message,
        platformChannelSpecifics,
        payload: payload,
      );
      print("show notification called with title: $title, message: $message");
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

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

  // Create a notification via API and add it to the cache
  static Future<bool> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? link,
    String? resourceId,
    bool showPushNotification = true,
  }) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Prepare notification data
      final Map<String, dynamic> notificationData = {
        'user': userId,
        'title': title,
        'message': message,
        'type': _typeToString(type),
        'link': link,
        'resourceId': resourceId,
      };

      // Make API call to create notification
      final uri = Uri.parse('$_apiBaseUrl/notifications');
      final response = await http
          .post(
        uri,
        headers: _getAuthHeaders(),
        body: json.encode(notificationData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Creating notification locally instead.');
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // If API call was successful, update local cache with the new data
          await fetchNotifications(backgroundRefresh: true);

          // Show push notification if requested
          if (showPushNotification) {
            await showLocalPushNotification(
              title: title,
              message: message,
              payload: link ?? resourceId,
            );
          }

          return true;
        } else {
          // If API returned an error, create locally as fallback
          print('API error creating notification: ${responseData['message']}');
          return _createLocalNotification(
            title: title,
            message: message,
            type: type,
            link: link,
            showPushNotification: showPushNotification,
          );
        }
      } else {
        // If HTTP error, create locally as fallback
        print('HTTP error ${response.statusCode} creating notification');
        return _createLocalNotification(
          title: title,
          message: message,
          type: type,
          link: link,
          showPushNotification: showPushNotification,
        );
      }
    } catch (e) {
      // If exception, create locally as fallback
      print('Error creating notification via API: $e');
      return _createLocalNotification(
        title: title,
        message: message,
        type: type,
        link: link,
        showPushNotification: showPushNotification,
      );
    }
  }

  // Helper to convert notification type to string
  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.shop:
        return 'shop';
      case NotificationType.offer:
        return 'offer';
      case NotificationType.order:
        return 'order';
      case NotificationType.info:
        return 'info';
      case NotificationType.error:
        return 'error';
      case NotificationType.system:
      default:
        return 'system';
    }
  }

  // Create a local notification (fallback method when API is unavailable)
  static Future<bool> _createLocalNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? link,
    bool showPushNotification = true,
  }) async {
    try {
      final userId = _getUserId() ?? '';

      // Generate a temporary local ID
      final id = 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Create notification model
      final notification = NotificationModel(
        id: id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        link: link,
        isRead: false,
      );

      // Get existing notifications and add new one at the beginning
      final notifications = getCachedNotifications();
      notifications.insert(0, notification);

      // Update cache
      await _cacheNotifications(notifications);

      // Show push notification if requested and permissions granted
      if (showPushNotification) {
        if (await _areNotificationsSupported()) {
          await showLocalPushNotification(
            title: title,
            message: message,
            payload: link,
          );
        } else {
          print("Notifications not permitted. Skipping push notification.");
        }
      }

      return true;
    } catch (e) {
      print('Error creating local notification: $e');
      return false;
    }
  }
}
