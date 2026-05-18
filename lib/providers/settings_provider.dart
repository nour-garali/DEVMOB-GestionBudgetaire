import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _hideBalances = false;
  String _language = 'Français';

  bool get isDarkMode => _isDarkMode;
  bool get hideBalances => _hideBalances;
  String get language => _language;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _hideBalances = prefs.getBool('hideBalances') ?? false;
    _language = prefs.getString('language') ?? 'Français';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> toggleHideBalances() async {
    _hideBalances = !_hideBalances;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideBalances', _hideBalances);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
  }

  // Helper pour obtenir le thème de l'application
  ThemeData getTheme() {
    if (_isDarkMode) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1644FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1644FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      );
    }
  }
}
