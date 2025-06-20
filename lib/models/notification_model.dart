import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum representing the type of notification
enum NotificationType { offer, shop, order, info, error, system }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.system,
    this.link,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? link,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert notification type from string
  static NotificationType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'offer':
        return NotificationType.offer;
      case 'shop':
        return NotificationType.shop;
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

  // Convert notification type to string
  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return 'offer';
      case NotificationType.shop:
        return 'shop';
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

  // Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] ?? json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _typeFromString(json['type'] ?? 'system'),
      link: json['link'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': _typeToString(type),
      'link': link,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
