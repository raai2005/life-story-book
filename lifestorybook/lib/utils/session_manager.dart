import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _lastLoginKey = 'last_login_date';
  static const String _isLoggedInKey = 'is_logged_in';
  static const int _sessionDays = 30;

  // Check if user needs to login again
  static Future<bool> shouldShowLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) {
      return true; // New user, show login
    }

    final lastLoginString = prefs.getString(_lastLoginKey);
    if (lastLoginString == null) {
      return true; // No last login date, show login
    }

    final lastLogin = DateTime.parse(lastLoginString);
    final now = DateTime.now();
    final difference = now.difference(lastLogin).inDays;

    return difference >= _sessionDays;
  }

  // Save login session
  static Future<void> saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
