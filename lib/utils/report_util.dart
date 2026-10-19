import '../models/class_room.dart';
import '../models/student.dart';
import 'attendance_repository.dart';
import 'student_repository.dart';

/// Present/total counts for one student.
class StudentStat {
  final Student student;
  final int present;
  final int total;

  const StudentStat(this.student, this.present, this.total);

  int get absent => total - present;
  double get percent => total == 0 ? 0 : present * 100 / total;
}

/// One student's attendance in one class (subject).
class StudentClassStat {
  final ClassRoom classRoom;
  final int present;
  final int total;

  /// 'yyyy-MM-dd' -> present, newest first.
  final Map<String, bool> days;

  const StudentClassStat(this.classRoom, this.present, this.total, this.days);

  double get percent => total == 0 ? 0 : present * 100 / total;
}

/// Read-only helpers that build the Attendance Report screens from the
/// data already stored by [AttendanceRepository].
class ReportUtil {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String formatMonth(DateTime d) =>
      '${_monthsLong[d.month - 1]} ${d.year}';

  /// Students that belong to a class, sorted by roll number.
  static List<Student> studentsFor(ClassRoom c) {
    final list = StudentRepository.getAll()
        .where((s) => c.includesDivision(s.division))
        .toList();
    list.sort((a, b) {
      final byRoll =
      a.rollNumber.toLowerCase().compareTo(b.rollNumber.toLowerCase());
      return byRoll != 0
          ? byRoll
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  /// Monthly summary: one row per student for the given month.
  /// Returns the stats and the number of days attendance was taken.
  static (List<StudentStat>, int) monthly(ClassRoom c, DateTime month) {
    final prefix =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-';
    final records = AttendanceRepository.getClassRecords(c.id);
    final days = records.entries.where((e) => e.key.startsWith(prefix)).toList();

    final stats = studentsFor(c).map((s) {
      var present = 0;
      var total = 0;
      for (final day in days) {
        final v = day.value[s.id];
        if (v == null) continue;
        total++;
        if (v) present++;
      }
      return StudentStat(s, present, total);
    }).toList();
    return (stats, days.length);
  }

  /// Student-wise summary across every class the student belongs to.
  static List<StudentClassStat> forStudent(
      Student s, List<ClassRoom> classes) {
    final result = <StudentClassStat>[];
    for (final c in classes) {
      if (!c.includesDivision(s.division)) continue;
      final records = AttendanceRepository.getClassRecords(c.id);
      final days = <String, bool>{};
      var present = 0;
      for (final e in records.entries) {
        final v = e.value[s.id];
        if (v == null) continue;
        days[e.key] = v;
        if (v) present++;
      }
      result.add(StudentClassStat(c, present, days.length, days));
    }
    return result;
  }
}