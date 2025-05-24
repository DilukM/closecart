import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:closecart/model/notificationModel.dart';
import 'package:closecart/services/notificationService.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First load cached notifications instantly
      _notifications = NotificationService.getCachedNotifications();
      setState(() {
        _isLoading = false;
      });

      // Then fetch fresh data from API
      final freshNotifications = await NotificationService.fetchNotifications();
      setState(() {
        _notifications = freshNotifications;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final success = await NotificationService.markAsRead(notification.id);
    if (success) {
      setState(() {
        final index = _notifications.indexOf(notification);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead) return;

    setState(() {
      _isMarkingAllAsRead = true;
    });

    final success = await NotificationService.markAllAsRead();

    setState(() {
      _isMarkingAllAsRead = false;

      if (success) {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All notifications marked as read')),
        );
      }
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final success =
        await NotificationService.deleteNotification(notification.id);

    if (success) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                _loadNotifications();
              });
            },
          ),
        ),
      );
    }
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final Color accentColor = _getNotificationColor(notification.type);

    return InkWell(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                : accentColor.withOpacity(0.3),
          ),
        ),
        child: Dismissible(
          key: Key(notification.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteNotification(notification),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: accentColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return Icons.local_offer;
      case NotificationType.shop:
        return Icons.storefront;
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.system:
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return Colors.orange;
      case NotificationType.shop:
        return Colors.blue;
      case NotificationType.order:
        return Colors.green;
      case NotificationType.info:
        return Colors.cyan;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.system:
      default:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll see notifications about offers and shops here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (hasUnread)
            IconButton(
              icon: _isMarkingAllAsRead
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _isMarkingAllAsRead ? null : _markAllAsRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading && _notifications.isEmpty
            ? ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => _buildShimmerItem(),
              )
            : _notifications.isEmpty
                ? _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(_errorMessage,
                            style: TextStyle(color: Colors.red)))
                    : ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.15),
                          _buildEmptyState(),
                        ],
                      )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotificationItem(_notifications[index]),
                  ),
      ),
    );
  }
}
