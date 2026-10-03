import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  static SharedPreferences? _preferences;

  /// Initialize the SharedPreferences instance.
  /// Call this method once inside your main() function before runApp().
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // ==================== SETTERS ====================

  static Future<bool> setString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  static Future<bool> setInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  static Future<bool> setDouble(String key, double value) async {
    return await _preferences?.setDouble(key, value) ?? false;
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences?.setStringList(key, value) ?? false;
  }

  // ==================== GETTERS ====================

  static String getString(String key, {String defaultValue = ''}) {
    return _preferences?.getString(key) ?? defaultValue;
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _preferences?.getInt(key) ?? defaultValue;
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences?.getDouble(key) ?? defaultValue;
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _preferences?.getBool(key) ?? defaultValue;
  }

  static List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return _preferences?.getStringList(key) ?? defaultValue;
  }

  // ==================== UTILITY METHODS ====================

  /// Remove a specific key-value pair
  static Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  /// Clear all stored preferences
  static Future<bool> clear() async {
    return await _preferences?.clear() ?? false;
  }

  static Future<SharedPrefsUtil> getInstance() async {
    if (_preferences == null) {
      await init();
    }
    return SharedPrefsUtil();

  }
}