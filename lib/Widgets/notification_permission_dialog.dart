import 'package:flutter/material.dart';
import 'package:closecart/services/notificationService.dart';
import 'package:provider/provider.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enable Notifications'),
      content: const Text(
        'To receive order updates and special offers, please enable notifications for CloseCart.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            final permissionGranted =
                await NotificationService.requestNotificationPermissions();

            // Update the provider
            if (context.mounted) {
              Provider.of<NotificationPermissionProvider>(context,
                      listen: false)
                  .permissionGranted = permissionGranted;

              // If permission was denied, show settings dialog
              if (!permissionGranted) {
                await showDialog(
                  context: context,
                  builder: (_) => const NotificationSettingsDialog(),
                );
              }
            }
          },
          child: const Text('Enable'),
        ),
      ],
    );
  }
}

class NotificationSettingsDialog extends StatelessWidget {
  const NotificationSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications Disabled'),
      content: const Text(
        'Notifications are disabled for CloseCart. To receive important updates, please enable them in your device settings.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            NotificationService.openNotificationSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
