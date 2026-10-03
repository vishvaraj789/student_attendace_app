import 'package:flutter/material.dart';
import '../login_page.dart';
import '../models/class_room.dart';
import '../models/student.dart';
import '../utils/attendance_repository.dart';
import '../utils/class_repository.dart';
import '../utils/shared_preference.dart';
import '../utils/student_repository.dart';

/// Read-only view: a student can only see their own attendance.
/// Faculty write the records; nothing on this screen can change them.
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  static const _minPercent = 75.0;

  Student? _findMe(String email) {
    for (final s in StudentRepository.getAll()) {
      if (s.email.toLowerCase() == email.toLowerCase()) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = SharedPrefsUtil.getString('user_name', defaultValue: 'Student');
    final email = SharedPrefsUtil.getString('user_email');
    final me = _findMe(email);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${me?.name ?? name}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                me == null
                    ? "Your attendance record"
                    : "Roll No: ${me.rollNumber}"
                    "${me.division.isEmpty ? '' : '  •  Division ${me.division}'}",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              if (me == null)
                _EmptyState(
                  icon: Icons.person_search_outlined,
                  title: "You're not in the student list",
                  message:
                  "No student with the email \"$email\" was found. Ask your "
                      "faculty to add you using this email.",
                )
              else
                ..._buildRecords(context, me),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecords(BuildContext context, Student me) {
    final classes = ClassRepository.getAll()
        .where((c) => c.includesDivision(me.division))
        .toList();
    if (classes.isEmpty) {
      return const [
        _EmptyState(
          icon: Icons.class_outlined,
          title: "No classes yet",
          message: "No classes have been created for your division yet.",
        ),
      ];
    }

    // Build one summary per class, counting only days this student has
    // an entry for (days before they were added are ignored).
    final summaries = <_ClassSummary>[];
    int totalPresent = 0;
    int totalDays = 0;
    for (final c in classes) {
      final records = AttendanceRepository.getClassRecords(c.id);
      final days = <_Day>[];
      records.forEach((date, statuses) {
        if (statuses.containsKey(me.id)) {
          days.add(_Day(date, statuses[me.id]!));
        }
      });
      final present = days.where((d) => d.present).length;
      totalPresent += present;
      totalDays += days.length;
      summaries.add(_ClassSummary(c, days, present));
    }

    final overall = totalDays == 0 ? 0.0 : totalPresent * 100 / totalDays;

    return [
      _OverallCard(
        percent: overall,
        present: totalPresent,
        absent: totalDays - totalPresent,
        hasData: totalDays > 0,
        minPercent: _minPercent,
      ),
      const SizedBox(height: 24),
      Text(
        "Your Classes",
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      ...summaries.map((s) => _ClassCard(summary: s, minPercent: _minPercent)),
    ];
  }
}

class _Day {
  final String date; // yyyy-MM-dd
  final bool present;
  _Day(this.date, this.present);
}

class _ClassSummary {
  final ClassRoom classRoom;
  final List<_Day> days; // newest first
  final int present;
  _ClassSummary(this.classRoom, this.days, this.present);

  int get absent => days.length - present;
  double get percent => days.isEmpty ? 0 : present * 100 / days.length;
}

Color _percentColor(double p, double min) {
  if (p >= min) return const Color(0xFF10B981);
  if (p >= min - 15) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _prettyDate(String key) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final parts = key.split('-');
  if (parts.length != 3) return key;
  final m = int.tryParse(parts[1]) ?? 1;
  return '${int.tryParse(parts[2]) ?? parts[2]} ${months[(m - 1).clamp(0, 11)]} ${parts[0]}';
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

class _OverallCard extends StatelessWidget {
  final double percent;
  final int present;
  final int absent;
  final bool hasData;
  final double minPercent;

  const _OverallCard({
    required this.percent,
    required this.present,
    required this.absent,
    required this.hasData,
    required this.minPercent,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasData ? _percentColor(percent, minPercent) : Colors.grey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: hasData ? percent / 100 : 0,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  hasData ? '${percent.toStringAsFixed(0)}%' : '--',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall attendance',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  hasData
                      ? '$present present  •  $absent absent'
                      : 'No attendance taken yet',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (hasData && percent < minPercent) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Below ${minPercent.toStringAsFixed(0)}% requirement',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final _ClassSummary summary;
  final double minPercent;

  const _ClassCard({required this.summary, required this.minPercent});

  @override
  Widget build(BuildContext context) {
    final c = summary.classRoom;
    final hasData = summary.days.isNotEmpty;
    final color = hasData ? _percentColor(summary.percent, minPercent) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(c.name,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [c.subject, c.divisionLabel]
                      .where((e) => e.isNotEmpty)
                      .join(' • '),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasData ? summary.percent / 100 : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasData
                      ? '${summary.present} present  •  ${summary.absent} absent  •  ${summary.days.length} days'
                      : 'No attendance taken yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing: Text(
            hasData ? '${summary.percent.toStringAsFixed(0)}%' : '--',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          children: [
            for (final d in summary.days)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      d.present ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: d.present
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_prettyDate(d.date))),
                    Text(
                      d.present ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: d.present
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}