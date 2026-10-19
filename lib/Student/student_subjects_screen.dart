import 'package:flutter/material.dart';
import 'student_data.dart';

/// 📚 Subjects: the student's subjects with percentage and schedule.
/// Tap a subject to see its day-by-day record.
class StudentSubjectsScreen extends StatelessWidget {
  const StudentSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = StudentData.load();
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: studentAppBar('Subjects'),
      body: data.subjects.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.class_outlined,
          title: 'No subjects yet',
          message: 'No classes have been created for your division yet.',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in data.subjects) _SubjectCard(summary: s),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectSummary summary;
  const _SubjectCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final c = summary.classRoom;
    final color = percentColor(summary.percent, hasData: summary.hasData);
    final time = c.startTime.format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(summary.title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (c.days.isNotEmpty) c.days.join(', '),
                    time,
                    c.divisionLabel,
                  ].join(' • '),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary.hasData ? summary.percent / 100 : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary.hasData
                      ? '${summary.present} present  •  ${summary.absent} absent  •  ${summary.total} classes'
                      : 'No attendance taken yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing: Text(
            summary.hasData ? '${summary.percent.toStringAsFixed(0)}%' : '--',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          children: [
            if (!summary.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nothing recorded yet.'),
              ),
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
                    Expanded(child: Text(prettyDate(d.date))),
                    Text(d.present ? 'Present' : 'Absent',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: d.present
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}