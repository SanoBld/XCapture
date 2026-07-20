import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

enum TileInfo { none, title, titleAndDate }
enum GalleryLayout { grid, list }

// App-wide settings: theme, language, accent, grid, startup tab, tile display
class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool useDynamicColor = true;
  int gridColumns = 3;
  String languageCode = 'en';
  Color accentColor = const Color(0xFF107C10);
  int startupTab = 0; // 0=Screenshots, 1=Clips, 2=Settings
  TileInfo tileInfo = TileInfo.title;
  GalleryLayout layout = GalleryLayout.grid;

  static const _prefLanguage = 'language_code';
  static const _prefAccent = 'accent_color';
  static const _prefStartupTab = 'startup_tab';
  static const _prefTileInfo = 'tile_info';
  static const _prefLayout = 'gallery_layout';

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
    startupTab = prefs.getInt(_prefStartupTab) ?? 0;
    final tileInfoIndex = prefs.getInt(_prefTileInfo);
    if (tileInfoIndex != null) tileInfo = TileInfo.values[tileInfoIndex];
    final layoutIndex = prefs.getInt(_prefLayout);
    if (layoutIndex != null) layout = GalleryLayout.values[layoutIndex];
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

  Future<void> setStartupTab(int index) async {
    startupTab = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefStartupTab, index);
  }

  Future<void> setTileInfo(TileInfo info) async {
    tileInfo = info;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTileInfo, info.index);
  }

  Future<void> setLayout(GalleryLayout value) async {
    layout = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefLayout, value.index);
  }
}
