import 'package:flutter/material.dart';

@immutable
class AppColors {
  static const white = const Color(0xFFFFFFFF);
  static const black = const Color(0xFF000000);

  static const MaterialColor primarySwatch = Colors.amber;
  static const MaterialColor primaryDarkSwatch = Colors.amber;

  static const Color primaryLight = Color.fromARGB(255, 234, 141, 1);
  static const Color primaryDark = Color.fromARGB(255, 255, 175, 3);

  static const Color accentLight = Color.fromARGB(255, 251, 251, 187);
  static const Color accentDark = Color.fromARGB(255, 161, 151, 13);

  static const Color backgroundLight = Color.fromARGB(255, 255, 255, 255);
  static const Color backgroundDark = Color.fromARGB(255, 31, 31, 31);

  static const Color surfaceLight = Color.fromARGB(255, 236, 236, 236);
  static const Color surfaceDark = Color.fromARGB(255, 54, 54, 54);

  static const Color textLight = Color(0xFF212121);
  static const Color textDark = Color(0xFFE0E0E0);

  static const Color buttonLight = Color.fromARGB(255, 255, 175, 3);
  static const Color buttonDark = Color.fromARGB(255, 255, 175, 3);

  static const primaryGradient = const LinearGradient(
    colors: [
      Color.fromARGB(255, 255, 175, 3),
      Color.fromARGB(255, 251, 255, 0)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
