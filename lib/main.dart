import 'package:closecart/Screens/BottomNav.dart';
import 'package:closecart/Screens/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:closecart/Util/theme.dart';

void main() {
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
            home: BottomNav(),
          );
        },
      ),
    );
  }
}
