import 'dart:convert';
import '../models/class_room.dart';
import 'shared_preference.dart';
import 'attendance_repository.dart';

/// Stores created classes on the device (SharedPreferences, as JSON).
class ClassRepository {
  static const _key = 'classes';

  static List<ClassRoom> getAll() {
    final raw = SharedPrefsUtil.getString(_key);
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ClassRoom.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<ClassRoom> classes) async {
    await SharedPrefsUtil.setString(
      _key,
      jsonEncode(classes.map((c) => c.toMap()).toList()),
    );
  }

  /// Deletes the class together with all of its attendance records.
  static Future<void> delete(List<ClassRoom> classes, String classId) async {
    classes.removeWhere((c) => c.id == classId);
    await saveAll(classes);
    await AttendanceRepository.deleteClass(classId);
  }
}