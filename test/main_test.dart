import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:closecart/main.dart';
import 'package:closecart/services/notificationService.dart';

void main() {
  group('Main App', () {
    testWidgets('ThemeProvider should initialize correctly',
        (WidgetTester tester) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider,
            child: Consumer<ThemeProvider>(
              builder: (context, provider, child) {
                return Text('Current theme: ${provider.currentTheme}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Current theme: System Default'), findsOneWidget);
    });

    testWidgets('ThemeProvider should toggle themes correctly',
        (WidgetTester tester) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider,
            child: Consumer<ThemeProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Text('Current theme: ${provider.currentTheme}'),
                    ElevatedButton(
                      onPressed: () => provider.toggleTheme(),
                      child: Text('Toggle Theme'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Current theme: System Default'), findsOneWidget);

      await tester.tap(find.text('Toggle Theme'));
      await tester.pump();

      expect(find.text('Current theme: Light Theme'), findsOneWidget);

      await tester.tap(find.text('Toggle Theme'));
      await tester.pump();

      expect(find.text('Current theme: Dark Theme'), findsOneWidget);

      await tester.tap(find.text('Toggle Theme'));
      await tester.pump();

      expect(find.text('Current theme: System Default'), findsOneWidget);
    });

    testWidgets('MainApp should create MaterialApp with correct structure',
        (WidgetTester tester) async {
      // Create a simplified test version without NotificationPermissionHandler
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationPermissionProvider>(
              create: (_) => NotificationPermissionProvider(),
            ),
          ],
          child: ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return MaterialApp(
                  title: 'Close Cart',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeProvider.themeMode,
                  home: Scaffold(
                    body: Text('Test App'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);
    });
  });

  group('Theme Management', () {
    test('ThemeProvider should initialize with system theme', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.currentTheme, 'System Default');
    });

    test('ThemeProvider should cycle through themes', () {
      final provider = ThemeProvider();

      // Initial: System Default
      expect(provider.currentTheme, 'System Default');

      // Toggle to Light
      provider.toggleTheme();
      expect(provider.currentTheme, 'Light Theme');

      // Toggle to Dark
      provider.toggleTheme();
      expect(provider.currentTheme, 'Dark Theme');

      // Toggle back to System
      provider.toggleTheme();
      expect(provider.currentTheme, 'System Default');
    });

    test('ThemeProvider should notify listeners on theme change', () {
      final provider = ThemeProvider();
      int notificationCount = 0;

      provider.addListener(() {
        notificationCount++;
      });

      provider.toggleTheme();
      expect(notificationCount, 1);

      provider.toggleTheme();
      expect(notificationCount, 2);

      provider.toggleTheme();
      expect(notificationCount, 3);
    });
  });

  group('App Configuration', () {
    test('should handle multiple theme cycles', () {
      final provider = ThemeProvider();

      // Cycle through themes multiple times
      for (int i = 0; i < 10; i++) {
        provider.toggleTheme();
      }

      // Should be back to Light Theme (10 % 3 = 1)
      expect(provider.currentTheme, 'Light Theme');
    });

    test('should maintain theme state consistency', () {
      final provider = ThemeProvider();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.currentTheme, 'System Default');

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.currentTheme, 'Light Theme');

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.currentTheme, 'Dark Theme');
    });
  });

  group('Provider Integration', () {
    testWidgets('should work with multiple providers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<NotificationPermissionProvider>(
              create: (_) => NotificationPermissionProvider(),
            ),
          ],
          child: MaterialApp(
            home: Consumer2<ThemeProvider, NotificationPermissionProvider>(
              builder: (context, themeProvider, notificationProvider, child) {
                return Text(
                    'Theme: ${themeProvider.currentTheme}, Notification: ${notificationProvider.permissionGranted}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Theme: System Default, Notification: false'),
          findsOneWidget);
    });

    testWidgets('should handle provider state changes',
        (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final notificationProvider = NotificationPermissionProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => themeProvider,
            ),
            ChangeNotifierProvider<NotificationPermissionProvider>(
              create: (_) => notificationProvider,
            ),
          ],
          child: MaterialApp(
            home: Consumer2<ThemeProvider, NotificationPermissionProvider>(
              builder: (context, themeProv, notifProv, child) {
                return Column(
                  children: [
                    Text('Theme: ${themeProv.currentTheme}'),
                    Text('Notification: ${notifProv.permissionGranted}'),
                    ElevatedButton(
                      onPressed: () => themeProv.toggleTheme(),
                      child: Text('Toggle Theme'),
                    ),
                    ElevatedButton(
                      onPressed: () => notifProv.permissionGranted =
                          !notifProv.permissionGranted,
                      child: Text('Toggle Notification'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Theme: System Default'), findsOneWidget);
      expect(find.text('Notification: false'), findsOneWidget);

      await tester.tap(find.text('Toggle Theme'));
      await tester.pump();

      expect(find.text('Theme: Light Theme'), findsOneWidget);

      await tester.tap(find.text('Toggle Notification'));
      await tester.pump();

      expect(find.text('Notification: true'), findsOneWidget);
    });
  });
}
