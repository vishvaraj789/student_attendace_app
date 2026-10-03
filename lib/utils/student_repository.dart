import 'dart:convert';
import 'package:student_attendace_app/utils/shared_preference.dart';

import '../models/student.dart';
import 'shared_preference.dart' hide SharedPrefsUtil;

/// Stores the student list on the device (SharedPreferences, as JSON).
/// Swap the body of these methods for Firebase/SQLite later without
/// touching the UI.
class StudentRepository {
  static const _key = 'students';

  /// READ: all saved students (empty list if none or data is unreadable).
  static List<Student> getAll() {
    final raw = SharedPrefsUtil.getString(_key);
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Student.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the full list. Used after every add / update / delete.
  static Future<void> saveAll(List<Student> students) async {
    await SharedPrefsUtil.setString(
      _key,
      jsonEncode(students.map((s) => s.toMap()).toList()),
    );
  }

  static int count() => getAll().length;
}