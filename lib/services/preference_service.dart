

import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _loggedInKey = 'logged_in';
  static const String _userTypeKey = 'user_type';
  static const String _userIdKey = 'user_id';

  // --- Logged In State ---
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  // --- User Type (for navigation) ---
  static Future<void> setUserDetails(String userId, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userTypeKey, userType);
    
  }

  static Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'userType': prefs.getString(_userTypeKey),
    };
  }

  // --- Clear all preferences on logout/sign out ---
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}