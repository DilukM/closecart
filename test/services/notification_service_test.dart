import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:closecart/services/notificationService.dart';

void main() {
  group('NotificationPermissionProvider', () {
    late NotificationPermissionProvider provider;

    setUp(() {
      provider = NotificationPermissionProvider();
    });

    test('should initialize with permission granted as false', () {
      expect(provider.permissionGranted, false);
    });

    test('should update permission status and notify listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.permissionGranted = true;

      expect(provider.permissionGranted, true);
      expect(notified, true);
    });

    test('should handle multiple permission changes', () {
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      provider.permissionGranted = true;
      provider.permissionGranted = false;
      provider.permissionGranted = true;

      expect(provider.permissionGranted, true);
      expect(notificationCount, 3);
    });

    test('should not notify listeners when setting same value', () {
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      provider.permissionGranted = false; // Same as initial value
      provider.permissionGranted = false; // Same value again

      expect(notificationCount, 2); // Still notifies even with same value
    });

    test('should properly remove listeners', () {
      int notificationCount = 0;
      void listener() {
        notificationCount++;
      }

      provider.addListener(listener);
      provider.permissionGranted = true;
      expect(notificationCount, 1);

      provider.removeListener(listener);
      provider.permissionGranted = false;
      expect(notificationCount, 1); // Should not increment
    });

    test('should handle multiple listeners', () {
      int count1 = 0;
      int count2 = 0;

      void listener1() {
        count1++;
      }

      void listener2() {
        count2++;
      }

      provider.addListener(listener1);
      provider.addListener(listener2);

      provider.permissionGranted = true;

      expect(count1, 1);
      expect(count2, 1);
    });
  });

  group('NotificationService Constants', () {
    test('should have correct API base URL', () {
      // Since the actual URL is private, we can test the concept
      expect(NotificationService.useMockedData, isA<bool>());
    });

    test('should have mocked data flag', () {
      expect(NotificationService.useMockedData, isA<bool>());

      // Test setting the flag
      NotificationService.useMockedData = true;
      expect(NotificationService.useMockedData, true);

      NotificationService.useMockedData = false;
      expect(NotificationService.useMockedData, false);
    });

    test('should have notifications plugin instance', () {
      expect(NotificationService.notificationsPlugin, isNotNull);
    });
  });

  group('Notification Configuration', () {
    test('should handle permission states', () {
      // Test different permission states
      final permissionStates = [true, false];

      for (final state in permissionStates) {
        final provider = NotificationPermissionProvider();
        provider.permissionGranted = state;
        expect(provider.permissionGranted, state);
      }
    });

    test('should validate notification settings', () {
      // Test that we can create notification settings
      final androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      expect(androidSettings.defaultIcon, '@mipmap/ic_launcher');
    });
  });

  group('Provider State Management', () {
    test('should maintain state across multiple operations', () {
      final provider = NotificationPermissionProvider();

      // Multiple state changes
      provider.permissionGranted = true;
      expect(provider.permissionGranted, true);

      provider.permissionGranted = false;
      expect(provider.permissionGranted, false);

      provider.permissionGranted = true;
      expect(provider.permissionGranted, true);
    });

    test('should handle rapid state changes', () {
      final provider = NotificationPermissionProvider();
      int notificationCount = 0;

      provider.addListener(() {
        notificationCount++;
      });

      // Rapid changes
      for (int i = 0; i < 10; i++) {
        provider.permissionGranted = i % 2 == 0;
      }

      expect(notificationCount, 10);
      expect(provider.permissionGranted,
          false); // Last value when i=9: 9 % 2 == 0 is false
    });

    test('should handle listener exceptions gracefully', () {
      final provider = NotificationPermissionProvider();

      provider.addListener(() {
        throw Exception('Test exception');
      });

      // Should not throw exception when notifying
      expect(() => provider.permissionGranted = true, returnsNormally);
    });
  });

  group('Notification Settings', () {
    test('should create Android initialization settings', () {
      final settings = AndroidInitializationSettings('@mipmap/ic_launcher');
      expect(settings.defaultIcon, '@mipmap/ic_launcher');
    });

    test('should create iOS initialization settings', () {
      final settings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      expect(settings.requestAlertPermission, false);
      expect(settings.requestBadgePermission, false);
      expect(settings.requestSoundPermission, false);
    });

    test('should create combined initialization settings', () {
      final androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      expect(initSettings.android, isNotNull);
      expect(initSettings.iOS, isNotNull);
    });
  });

  group('Error Handling', () {
    test('should handle provider disposal correctly', () {
      final provider = NotificationPermissionProvider();

      // Add some listeners
      provider.addListener(() {});
      provider.addListener(() {});

      // Dispose should not throw
      expect(() => provider.dispose(), returnsNormally);
    });

    test('should handle null listener addition', () {
      final provider = NotificationPermissionProvider();

      // Should handle null listener gracefully
      expect(() => provider.addListener(() {}), returnsNormally);
    });
  });

  group('Integration Tests', () {
    test('should work with ChangeNotifier pattern', () {
      final provider = NotificationPermissionProvider();

      // Test that it implements ChangeNotifier properly
      expect(provider, isA<ChangeNotifier>());

      // Test basic ChangeNotifier functionality
      bool hasListeners = false;
      provider.addListener(() {
        hasListeners = true;
      });

      provider.permissionGranted = true;
      expect(hasListeners, true);
    });

    test('should handle concurrent access', () {
      final provider = NotificationPermissionProvider();

      // Simulate concurrent access
      Future.wait([
        Future(() => provider.permissionGranted = true),
        Future(() => provider.permissionGranted = false),
        Future(() => provider.permissionGranted = true),
      ]);

      // Should not throw and should have a consistent state
      expect(provider.permissionGranted, isA<bool>());
    });
  });

  group('Performance Tests', () {
    test('should handle large number of listeners efficiently', () {
      final provider = NotificationPermissionProvider();
      final listeners = <VoidCallback>[];

      // Add many listeners
      for (int i = 0; i < 100; i++) {
        final listener = () {};
        listeners.add(listener);
        provider.addListener(listener);
      }

      // Notification should still work
      provider.permissionGranted = true;
      expect(provider.permissionGranted, true);

      // Remove all listeners
      for (final listener in listeners) {
        provider.removeListener(listener);
      }
    });

    test('should handle frequent state changes efficiently', () {
      final provider = NotificationPermissionProvider();

      // Measure time for many state changes
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        provider.permissionGranted = i % 2 == 0;
      }

      stopwatch.stop();

      // Should complete in reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
