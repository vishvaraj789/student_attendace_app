import 'package:flutter/material.dart';
import 'student_data.dart';

/// 📅 Attendance History: every day, newest first, filterable by subject.
class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _Entry {
  final String subject;
  final DayRecord day;
  _Entry(this.subject, this.day);
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  final _data = StudentData.load();
  String? _subject; // null = all
  bool? _present; // null = all

  @override
  Widget build(BuildContext context) {
    final entries = <_Entry>[
      for (final s in _data.subjects)
        if (_subject == null || s.title == _subject)
          for (final d in s.days)
            if (_present == null || d.present == _present) _Entry(s.title, d),
    ]..sort((a, b) => b.day.date.compareTo(a.day.date));

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: studentAppBar('Attendance History'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _subject == null,
                  onSelected: (_) => setState(() => _subject = null),
                ),
                for (final s in _data.subjects) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(s.title),
                    selected: _subject == s.title,
                    onSelected: (_) => setState(() => _subject = s.title),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Present'),
                  selected: _present == true,
                  onSelected: (v) => setState(() => _present = v ? true : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Absent'),
                  selected: _present == false,
                  onSelected: (v) =>
                      setState(() => _present = v ? false : null),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.history,
                title: 'No records',
                message: 'No attendance has been recorded for this filter.',
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = entries[i];
                final p = e.day.present;
                return Container(
                  decoration: cardDecoration(),
                  child: ListTile(
                    leading: Icon(
                      p ? Icons.check_circle : Icons.cancel,
                      color: p
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    title: Text(e.subject,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(prettyDate(e.day.date)),
                    trailing: Text(
                      p ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: p
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}