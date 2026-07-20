import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

// App-wide settings: theme mode, dynamic color, grid density, language, accent
class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool useDynamicColor = true;
  int gridColumns = 3;
  String languageCode = 'en';
  Color accentColor = const Color(0xFF107C10);

  static const _prefLanguage = 'language_code';
  static const _prefAccent = 'accent_color';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(AppConstants.prefThemeMode);
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => ThemeMode.system,
    );
    useDynamicColor = prefs.getBool(AppConstants.prefUseDynamicColor) ?? true;
    gridColumns = prefs.getInt(AppConstants.prefGridColumns) ?? 3;
    languageCode = prefs.getString(_prefLanguage) ?? 'en';
    final accentValue = prefs.getInt(_prefAccent);
    if (accentValue != null) accentColor = Color(accentValue);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  Future<void> setDynamicColor(bool value) async {
    useDynamicColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefUseDynamicColor, value);
  }

  Future<void> setGridColumns(int value) async {
    gridColumns = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefGridColumns, value);
  }

  Future<void> setLanguageCode(String code) async {
    languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguage, code);
  }

  Future<void> setAccentColor(Color color) async {
    accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefAccent, color.toARGB32());
  }
}
