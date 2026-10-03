import 'dart:convert';
import '../models/faculty.dart';
import 'shared_preference.dart';

/// Faculty accounts, created and managed by the admin.
class FacultyRepository {
  static const _key = 'faculty_accounts';
  static const _migratedKey = 'faculty_migrated';

  static List<Faculty> getAll() {
    _migrateLegacyOnce();
    final raw = SharedPrefsUtil.getString(_key);
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Faculty.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<Faculty> list) async {
    await SharedPrefsUtil.setString(
      _key,
      jsonEncode(list.map((f) => f.toMap()).toList()),
    );
  }

  /// Returns the matching faculty for a login, or null.
  static Faculty? authenticate(String email, String password) {
    for (final f in getAll()) {
      if (f.email.toLowerCase() == email.trim().toLowerCase() &&
          f.password.isNotEmpty &&
          f.password == password) {
        return f;
      }
    }
    return null;
  }

  /// Older versions stored a single faculty account under faculty_* keys.
  /// Move it into the list once so it keeps working.
  static void _migrateLegacyOnce() {
    if (SharedPrefsUtil.getBool(_migratedKey)) return;
    final email = SharedPrefsUtil.getString('faculty_email');
    if (email.isNotEmpty && SharedPrefsUtil.getString(_key).isEmpty) {
      final legacy = Faculty(
        id: 'legacy',
        name: SharedPrefsUtil.getString('faculty_name', defaultValue: 'Faculty'),
        email: email,
        password: SharedPrefsUtil.getString('faculty_password'),
      );
      SharedPrefsUtil.setString(_key, jsonEncode([legacy.toMap()]));
    }
    SharedPrefsUtil.setBool(_migratedKey, true);
  }
}