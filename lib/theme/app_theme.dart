import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central place for app theming.
/// Usage in main.dart:
///   MaterialApp(
///     theme: AppTheme.light,
///     darkTheme: AppTheme.dark,
///     themeMode: ThemeMode.system,
///   )
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF064E3B);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: _appBarTheme(colorScheme, isDark),
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme scheme, bool isDark) {
    return AppBarTheme(
      // Colors
      backgroundColor: seed, // exact brand green, not the generated tone
      foregroundColor: Colors.white, // title + icons default color
      surfaceTintColor: Colors.transparent, // stops M3 tint when scrolling

      // Elevation
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),

      // Layout
      centerTitle: false,
      titleSpacing: 16,
      toolbarHeight: 60,

      // Typography
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      toolbarTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),

      // Icons
      iconTheme: IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 24),

      // Status bar icons (time, battery) so they stay readable on the bar
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS
      ),

      // Optional: rounded bottom corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }
}