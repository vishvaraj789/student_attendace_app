import 'dart:convert';
import '../models/app_user.dart';
import '../models/class_room.dart';
import 'cloud_sync.dart';
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
    await CloudSync.syncCollection(
      'classes',
      classes.map((c) => c.toMap()).toList(),
    );
  }

  /// Adds one class without touching the others.
  static Future<void> add(ClassRoom classRoom) async {
    final all = getAll()..add(classRoom);
    await saveAll(all);
  }

  /// Classes the logged-in user may see: everything for admin/students,
  /// and for faculty only their own classes plus unassigned ones.
  static List<ClassRoom> visibleToCurrentUser() {
    final all = getAll();
    final role = SharedPrefsUtil.getString('user_role');
    if (role != UserRole.faculty.asString) return all;
    final me = SharedPrefsUtil.getString('user_id');
    return all.where((c) => c.facultyId.isEmpty || c.facultyId == me).toList();
  }

  /// Classes assigned to one faculty member.
  static List<ClassRoom> assignedTo(String facultyId) {
    if (facultyId.isEmpty) return [];
    return getAll().where((c) => c.facultyId == facultyId).toList();
  }

  /// Frees up every class of a faculty member (used when they are deleted).
  static Future<void> unassignFaculty(String facultyId) async {
    final all = getAll();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].facultyId == facultyId) {
        all[i] = all[i].copyWith(facultyId: '');
        changed = true;
      }
    }
    if (changed) await saveAll(all);
  }

  /// Deletes the class together with all of its attendance records.
  static Future<void> delete(List<ClassRoom> classes, String classId) async {
    classes.removeWhere((c) => c.id == classId);
    final all = getAll()..removeWhere((c) => c.id == classId);
    await saveAll(all);
    await AttendanceRepository.deleteClass(classId);
  }
}