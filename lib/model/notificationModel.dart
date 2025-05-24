import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum representing the type of notification
enum NotificationType {
  system,
  shop,
  offer,
  order,
  info,
  error,
}

class NotificationModel {
  final String id;
  final String userId; // Reference to Consumer/user
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? link; // Optional link to navigate to
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.system,
    this.isRead = false,
    this.link,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory method to create a notification from JSON data
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId:
          json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      isRead: json['isRead'] ?? false,
      link: json['link'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Convert notification to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'title': title,
      'message': message,
      'type': _typeToString(type),
      'isRead': isRead,
      'link': link,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Helper method to parse notification type from string
  static NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.system;

    switch (typeStr.toLowerCase()) {
      case 'shop':
        return NotificationType.shop;
      case 'offer':
        return NotificationType.offer;
      case 'order':
        return NotificationType.order;
      case 'info':
        return NotificationType.info;
      case 'error':
        return NotificationType.error;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  /// Helper method to convert notification type to string
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

  /// Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    String? link,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get color based on notification type
  Color getTypeColor(BuildContext context) {
    switch (type) {
      case NotificationType.shop:
        return Colors.green;
      case NotificationType.offer:
        return Colors.orange;
      case NotificationType.order:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.system:
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Get icon based on notification type
  IconData getTypeIcon() {
    switch (type) {
      case NotificationType.shop:
        return Icons.store;
      case NotificationType.offer:
        return Icons.discount;
      case NotificationType.order:
        return Icons.shopping_cart;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Notification{id: $id, title: $title, type: ${_typeToString(type)}}';
}
