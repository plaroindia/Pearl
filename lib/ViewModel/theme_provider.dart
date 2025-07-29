import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
      (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Default theme is now Dark
  ThemeNotifier() : super(ThemeMode.dark);

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

// Define your app themes here
class AppThemes {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black87,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Color(0xFF1E1E1E),
      background: Colors.black87,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black87,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    dividerColor: Colors.grey[700],
    cardTheme: CardTheme(
      color: Colors.black87,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black87,
      secondary: Colors.blueAccent,
      surface: Colors.white,
      background: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,
    ),
    dividerColor: Colors.grey[300],
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
    ),
  );
}