import 'package:flutter/material.dart';
import '../models/class_room.dart';
import '../models/student.dart';
import '../utils/attendance_repository.dart';
import '../utils/class_repository.dart';
import '../utils/shared_preference.dart';
import '../utils/student_repository.dart';
import '../admin/admin_ui.dart';

// Student screens share the admin look (AdminUi, AdminCard, ...).
export '../admin/admin_ui.dart';

/// Minimum attendance a student must keep.
const double kMinPercent = 75.0;

/// One day of attendance for one subject.
class DayRecord {
  final String date; // yyyy-MM-dd
  final bool present;
  const DayRecord(this.date, this.present);
}

/// Attendance summary of one subject for the logged-in student.
class SubjectSummary {
  final ClassRoom classRoom;
  final List<DayRecord> days; // newest first
  final int present;
  const SubjectSummary(this.classRoom, this.days, this.present);

  int get total => days.length;
  int get absent => total - present;
  bool get hasData => total > 0;
  double get percent => total == 0 ? 0 : present * 100 / total;

  /// Subject title shown to the student (subject name, else class name).
  String get title =>
      classRoom.subject.isNotEmpty ? classRoom.subject : classRoom.name;

  /// Classes the student must attend in a row to reach [kMinPercent].
  int get classesNeeded {
    if (!hasData || percent >= kMinPercent) return 0;
    const r = kMinPercent / 100;
    return ((r * total - present) / (1 - r)).ceil();
  }

  /// Classes the student can still miss and stay at/above [kMinPercent].
  int get canSkip {
    if (!hasData || percent < kMinPercent) return 0;
    const r = kMinPercent / 100;
    final n = (present / r - total).floor();
    return n < 0 ? 0 : n;
  }
}

/// Everything the student screens need, computed from local data.
class StudentData {
  final Student? me;
  final String email;
  final String fallbackName;
  final List<SubjectSummary> subjects;

  const StudentData._(this.me, this.email, this.fallbackName, this.subjects);

  static StudentData load() {
    final email = SharedPrefsUtil.getString('user_email');
    final name = SharedPrefsUtil.getString('user_name', defaultValue: 'Student');

    Student? me;
    for (final s in StudentRepository.getAll()) {
      if (s.email.toLowerCase() == email.toLowerCase()) {
        me = s;
        break;
      }
    }
    if (me == null) return StudentData._(null, email, name, const []);
    final student = me; // non-null copy, safe to use inside closures

    final subjects = <SubjectSummary>[];
    for (final c in ClassRepository.getAll()) {
      if (!c.includesDivision(student.division)) continue;
      final days = <DayRecord>[];
      AttendanceRepository.getClassRecords(c.id).forEach((date, statuses) {
        // Only days this student has an entry for are counted.
        if (statuses.containsKey(student.id)) {
          days.add(DayRecord(date, statuses[student.id]!));
        }
      });
      subjects.add(SubjectSummary(c, days, days.where((d) => d.present).length));
    }
    return StudentData._(me, email, name, subjects);
  }

  String get name => me?.name ?? fallbackName;
  int get totalPresent => subjects.fold(0, (a, s) => a + s.present);
  int get totalClasses => subjects.fold(0, (a, s) => a + s.total);
  int get totalAbsent => totalClasses - totalPresent;
  bool get hasData => totalClasses > 0;
  double get overallPercent =>
      totalClasses == 0 ? 0 : totalPresent * 100 / totalClasses;
}

// ------------------------------------------------------------ UI helpers

Color percentColor(double p, {bool hasData = true}) {
  if (!hasData) return Colors.grey;
  if (p >= kMinPercent) return const Color(0xFF10B981);
  if (p >= kMinPercent - 15) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String prettyDate(String key) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final parts = key.split('-');
  if (parts.length != 3) return key;
  final m = int.tryParse(parts[1]) ?? 1;
  return '${int.tryParse(parts[2]) ?? parts[2]} '
      '${months[(m - 1).clamp(0, 11)]} ${parts[0]}';
}

BoxDecoration cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AdminUi.line),
);

AppBar studentAppBar(String title) => adminAppBar(title);

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AdminUi.blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AdminUi.blue),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminUi.muted, fontSize: 14)),
        ],
      ),
    );
  }
}