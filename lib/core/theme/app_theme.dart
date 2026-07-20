import 'package:flutter/material.dart';

// Material You theme builder, with optional dynamic color scheme
class AppTheme {
  static ThemeData light(ColorScheme? dynamicScheme, Color seed) {
    final scheme = dynamicScheme ?? ColorScheme.fromSeed(seedColor: seed);
    return _build(scheme);
  }

  static ThemeData dark(ColorScheme? dynamicScheme, Color seed) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
