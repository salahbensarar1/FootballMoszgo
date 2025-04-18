import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // To get system theme

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  // Optional: Get current brightness based on mode and system
  Brightness get currentBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
      default:
      // Get system brightness
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Check system brightness if mode is system
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      // Otherwise, check the explicit mode
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    // Persist preference (optional but recommended) - See Step 5
    // _saveThemePreference();
    notifyListeners(); // Notify widgets listening to this provider
  }

// --- Optional: Persistence ---
// You would typically load the saved preference in the constructor
// and save it in toggleTheme using a package like shared_preferences.
// Example (needs shared_preferences package):
/*
  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode'); // Example key
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners(); // Notify after loading
    }
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }
  */
// --------------------------

}