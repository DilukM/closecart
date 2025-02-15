import 'package:closecart/Util/colors.dart';
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: AppColors.primarySwatch,
  scaffoldBackgroundColor: AppColors.backgroundLight,
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryLight,
    secondary: AppColors.accentLight,
    background: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    onBackground: AppColors.textLight,
    onSurface: AppColors.textLight,
    onError: AppColors.textLight,
    onPrimary: AppColors.textLight,
    onSecondary: AppColors.textLight,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    iconTheme: IconThemeData(color: AppColors.black),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: AppColors.textLight),
    displayMedium: TextStyle(color: AppColors.textLight),
    displaySmall: TextStyle(color: AppColors.textLight),
    headlineLarge: TextStyle(color: AppColors.textLight),
    headlineMedium:
        TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: AppColors.textLight),
    titleLarge: TextStyle(color: AppColors.textLight),
    titleMedium: TextStyle(color: AppColors.primaryLight),
    titleSmall: TextStyle(color: AppColors.textLight),
    bodyLarge: TextStyle(color: AppColors.textLight),
    bodyMedium: TextStyle(color: AppColors.textLight),
    bodySmall: TextStyle(color: AppColors.textLight),
    labelLarge: TextStyle(color: AppColors.textLight),
    labelMedium: TextStyle(color: AppColors.textLight),
    labelSmall: TextStyle(color: AppColors.textLight),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: AppColors.buttonDark,
    textTheme: ButtonTextTheme.primary,
  ),
);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.yellow,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primaryDark,
    secondary: AppColors.accentDark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    onBackground: AppColors.textDark,
    onSurface: AppColors.textDark,
    onError: AppColors.textDark,
    onPrimary: AppColors.textDark,
    onSecondary: AppColors.textDark,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryDark,
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    iconTheme: IconThemeData(color: AppColors.white),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: AppColors.textDark),
    displayMedium: TextStyle(color: AppColors.textDark),
    displaySmall: TextStyle(color: AppColors.textDark),
    headlineLarge: TextStyle(color: AppColors.textDark),
    headlineMedium:
        TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: AppColors.textDark),
    titleLarge: TextStyle(color: AppColors.textDark),
    titleMedium: TextStyle(color: AppColors.primaryDark),
    titleSmall: TextStyle(color: AppColors.textDark),
    bodyLarge: TextStyle(color: AppColors.textDark),
    bodyMedium: TextStyle(color: AppColors.textDark),
    bodySmall: TextStyle(color: AppColors.textDark),
    labelLarge: TextStyle(color: AppColors.textDark),
    labelMedium: TextStyle(color: AppColors.textDark),
    labelSmall: TextStyle(color: AppColors.textDark),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: AppColors.buttonDark,
    textTheme: ButtonTextTheme.primary,
  ),
);
