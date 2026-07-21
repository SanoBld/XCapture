import 'package:flutter/material.dart';

// Material You theme builder, with optional dynamic color scheme
class AppTheme {
  static ThemeData light(ColorScheme? dynamicScheme, Color seed) {
    // FIX: some devices' dynamic (wallpaper) scheme has almost no contrast
    // between surface and card colors (looked flat black&white). Re-generate
    // a full Material 3 palette using the wallpaper's primary color as seed
    // instead of using the raw OS scheme directly.
    final scheme = ColorScheme.fromSeed(
      seedColor: dynamicScheme?.primary ?? seed,
    );
    return _build(scheme);
  }

  static ThemeData dark(ColorScheme? dynamicScheme, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: dynamicScheme?.primary ?? seed,
      brightness: Brightness.dark,
    );
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
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: const StadiumBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
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
