import 'dart:convert';
import 'shared_preference.dart';

/// Attendance is stored as:
/// { classId: { 'yyyy-MM-dd': { studentId: true(present)/false(absent) } } }
class AttendanceRepository {
  static const _key = 'attendance';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _readAll() {
    final raw = SharedPrefsUtil.getString(_key);
    if (raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Saved attendance for one class on one day (empty if never taken).
  static Map<String, bool> get(String classId, DateTime date) {
    final classData = _readAll()[classId];
    if (classData == null) return {};
    final day = (classData as Map)[dateKey(date)];
    if (day == null) return {};
    return Map<String, bool>.from(day as Map);
  }

  static Future<void> save(
      String classId,
      DateTime date,
      Map<String, bool> status,
      ) async {
    final all = _readAll();
    final classData = Map<String, dynamic>.from((all[classId] ?? {}) as Map);
    classData[dateKey(date)] = status;
    all[classId] = classData;
    await SharedPrefsUtil.setString(_key, jsonEncode(all));
  }

  static Future<void> deleteClass(String classId) async {
    final all = _readAll();
    all.remove(classId);
    await SharedPrefsUtil.setString(_key, jsonEncode(all));
  }

  /// Every day attendance was taken for a class, newest first:
  /// { 'yyyy-MM-dd': { studentId: present } }
  static Map<String, Map<String, bool>> getClassRecords(String classId) {
    final classData = _readAll()[classId];
    if (classData == null) return {};
    final keys = (classData as Map).keys.cast<String>().toList()
      ..sort((a, b) => b.compareTo(a));
    return {
      for (final k in keys)
        k: Map<String, bool>.from(classData[k] as Map),
    };
  }

  /// Number of days attendance has been taken for this class.
  static int daysTaken(String classId) {
    final classData = _readAll()[classId];
    return classData == null ? 0 : (classData as Map).length;
  }
}