import 'package:closecart/Screens/Auth/login.dart';
import 'package:closecart/Screens/Auth/register.dart';
import 'package:closecart/Screens/Auth/splash.dart';
import 'package:closecart/Screens/BottomNav.dart';
import 'package:closecart/Screens/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:closecart/Util/theme.dart';

import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('authBox');
  runApp(MainApp());
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
          return MaterialApp(
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
              '/editProfile': (context) => const EditProfilePage(),
            },
          );
        },
      ),
    );
  }
}
