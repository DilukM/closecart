import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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
  });

  group('Simple Widget Tests', () {
    testWidgets('should create basic widget with provider',
        (WidgetTester tester) async {
      final provider = NotificationPermissionProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NotificationPermissionProvider>(
            create: (_) => provider,
            child: Consumer<NotificationPermissionProvider>(
              builder: (context, prov, child) {
                return Text('Permission: ${prov.permissionGranted}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Permission: false'), findsOneWidget);
    });

    testWidgets('should update UI when permission changes',
        (WidgetTester tester) async {
      final provider = NotificationPermissionProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NotificationPermissionProvider>(
            create: (_) => provider,
            child: Consumer<NotificationPermissionProvider>(
              builder: (context, prov, child) {
                return Column(
                  children: [
                    Text('Permission: ${prov.permissionGranted}'),
                    ElevatedButton(
                      onPressed: () {
                        prov.permissionGranted = !prov.permissionGranted;
                      },
                      child: Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Permission: false'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Permission: true'), findsOneWidget);
    });
  });

  group('Provider State Management', () {
    test('should maintain state across multiple operations', () {
      final provider = NotificationPermissionProvider();

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

      for (int i = 0; i < 10; i++) {
        provider.permissionGranted = i % 2 == 0;
      }

      expect(notificationCount, 10);
      expect(provider.permissionGranted,
          false); // Last value when i=9: 9 % 2 == 0 is false
    });
  });

  group('Error Handling', () {
    test('should handle provider disposal correctly', () {
      final provider = NotificationPermissionProvider();

      provider.addListener(() {});
      provider.addListener(() {});

      expect(() => provider.dispose(), returnsNormally);
    });

    test('should handle listener management', () {
      final provider = NotificationPermissionProvider();
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

      provider.removeListener(listener1);
      provider.permissionGranted = false;

      expect(count1, 1); // Should not increment
      expect(count2, 2); // Should increment
    });
  });
}
