import 'package:closecart/Screens/Auth/login.dart';
import 'package:closecart/Screens/Auth/register.dart';
import 'package:closecart/Screens/Auth/splash.dart';
import 'package:closecart/Screens/BottomNav.dart';
import 'package:closecart/Screens/edit_profile.dart';
import 'package:closecart/widgets/notification_permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:closecart/Util/theme.dart';
import 'package:closecart/services/geofence_service.dart';
import 'package:closecart/services/notificationService.dart';
import 'package:toastification/toastification.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:closecart/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive boxes
  await Hive.openBox('authBox');

  // Initialize cache service
  await CacheService.init();

  // Clean expired cache on app start
  await CacheService.cleanExpiredCache();

  // Initialize notifications
  await NotificationService.initializeNotifications();

  // Always check current notification permission status from system
  final permissionGranted =
      await NotificationService.checkCurrentPermissionStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GeofenceService>(
          create: (_) => GeofenceService(),
        ),
        // Add notification permission state provider with initial value from system
        ChangeNotifierProvider<NotificationPermissionProvider>(
          create: (_) => NotificationPermissionProvider()
            ..permissionGranted = permissionGranted,
        ),
      ],
      child: MainApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  String get currentTheme {
    if (_themeMode == ThemeMode.light) return "Light Theme";
    if (_themeMode == ThemeMode.dark) return "Dark Theme";
    return "System Default";
  }
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return NotificationPermissionHandler(
            child: MaterialApp(
              title: 'Close Cart',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/login': (context) => const LoginPage(),
                '/register': (context) => const RegisterPage(),
                '/home': (context) => const BottomNav(),
              },
            ),
          );
        },
      ),
    );
  }
}
