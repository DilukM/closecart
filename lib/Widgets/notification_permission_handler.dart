import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:closecart/services/notificationService.dart';

class NotificationPermissionHandler extends StatefulWidget {
  final Widget child;

  const NotificationPermissionHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationPermissionHandler> createState() =>
      _NotificationPermissionHandlerState();
}

class _NotificationPermissionHandlerState
    extends State<NotificationPermissionHandler> {
  @override
  void initState() {
    super.initState();
    // Delay the check briefly to allow the UI to render first
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        checkNotificationPermission();
      }
    });
  }

  Future<void> checkNotificationPermission() async {
    // Check current permission status - this now checks the actual system status, not our cached value
    final permissionGranted =
        await NotificationService.checkCurrentPermissionStatus();

    // Update the provider with the latest permission state
    final permissionProvider =
        Provider.of<NotificationPermissionProvider>(context, listen: false);
    permissionProvider.permissionGranted = permissionGranted;

    // If permission is not granted, show the dialog
    if (!permissionGranted && mounted) {
      final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (_) => NotificationPermissionDialog(),
          ) ??
          false;

      if (shouldOpenSettings && mounted) {
        await NotificationService.openNotificationSettings();

        // Check permission again after they return from settings
        final newStatus =
            await NotificationService.checkCurrentPermissionStatus();
        permissionProvider.permissionGranted = newStatus;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class NotificationPermissionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enable Notifications'),
      content: Text(
        'To receive important updates about your orders and offers, please enable notifications for CloseCart.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text('Open Settings'),
        ),
      ],
    );
  }
}

class NotificationSettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Notifications Disabled'),
      content: Text(
        'Notifications are currently disabled for CloseCart. To receive important updates, please enable them in your device settings.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text('Open Settings'),
        ),
      ],
    );
  }
}
