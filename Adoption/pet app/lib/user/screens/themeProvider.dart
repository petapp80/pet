import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  ThemeProvider(bool isDarkTheme) {
    _loadThemePreference();
  }

  // Load theme preference from SharedPreferences
  _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    notifyListeners(); // Notify listeners when the theme is loaded
  }

  // Save the theme preference to SharedPreferences
  _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', value);
    _isDarkTheme = value;
    notifyListeners(); // Notify listeners when the theme changes
  }

  // Toggle theme
  toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _saveThemePreference(_isDarkTheme);
    notifyListeners(); // Notify listeners when the theme is toggled
  }
}
