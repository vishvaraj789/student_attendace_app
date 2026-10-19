import 'package:flutter/material.dart';
import '../utils/attendance_repository.dart';
import 'student_data.dart';

enum NoticeLevel { warning, info, good }

class StudentNotice {
  final NoticeLevel level;
  final String title;
  final String message;
  const StudentNotice(this.level, this.title, this.message);
}

/// Notifications are generated from the student's own attendance data
/// (there is no push backend), so they are always up to date.
List<StudentNotice> buildNotifications(StudentData d) {
  final out = <StudentNotice>[];
  if (d.me == null) return out;

  final now = DateTime.now();
  final today = AttendanceRepository.dateKey(now);
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final todayLabel = wd[now.weekday - 1];

  for (final s in d.subjects) {
    if (s.hasData && s.percent < kMinPercent) {
      out.add(StudentNotice(
        NoticeLevel.warning,
        'Low attendance: ${s.title}',
        'You are at ${s.percent.toStringAsFixed(1)}%. Attend the next '
            '${s.classesNeeded} class${s.classesNeeded == 1 ? '' : 'es'} '
            'to reach ${kMinPercent.toStringAsFixed(0)}%.',
      ));
    }

    for (final day in s.days) {
      if (day.date == today) {
        out.add(StudentNotice(
          day.present ? NoticeLevel.good : NoticeLevel.warning,
          'Marked ${day.present ? 'present' : 'absent'} today',
          '${s.title} attendance was recorded for today.',
        ));
      }
    }

    if (s.classRoom.days.contains(todayLabel) &&
        !s.days.any((x) => x.date == today)) {
      out.add(StudentNotice(
        NoticeLevel.info,
        'Class today: ${s.title}',
        'Scheduled at ${s.classRoom.startTime.hour.toString().padLeft(2, '0')}:'
            '${s.classRoom.startTime.minute.toString().padLeft(2, '0')}.',
      ));
    }
  }

  // Absences in the last 7 days.
  final cutoff = AttendanceRepository.dateKey(
      now.subtract(const Duration(days: 7)));
  for (final s in d.subjects) {
    final recent =
        s.days.where((x) => !x.present && x.date.compareTo(cutoff) >= 0).length;
    if (recent > 0) {
      out.add(StudentNotice(
        NoticeLevel.info,
        'Recent absences: ${s.title}',
        'You were absent $recent time${recent == 1 ? '' : 's'} in the last 7 days.',
      ));
    }
  }

  if (d.hasData &&
      d.overallPercent >= kMinPercent &&
      !out.any((n) => n.level == NoticeLevel.warning)) {
    out.add(const StudentNotice(
      NoticeLevel.good,
      'Great job!',
      'Your attendance is above the requirement in every subject.',
    ));
  }
  return out;
}

/// 🔔 Notifications
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = buildNotifications(StudentData.load());
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: studentAppBar('Notifications'),
      body: notices.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.notifications_none,
          title: "You're all caught up",
          message: 'Alerts about your attendance will show up here.',
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = notices[i];
          final (icon, color) = switch (n.level) {
            NoticeLevel.warning => (
            Icons.warning_amber_rounded,
            const Color(0xFFEF4444)
            ),
            NoticeLevel.info => (
            Icons.info_outline,
            const Color(0xFF0EA5E9)
            ),
            NoticeLevel.good => (
            Icons.check_circle_outline,
            const Color(0xFF10B981)
            ),
          };
          return Container(
            decoration: cardDecoration(),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              title: Text(n.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(n.message),
            ),
          );
        },
      ),
    );
  }
}