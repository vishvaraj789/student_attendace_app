import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/class_room.dart';
import '../models/student.dart';
import '../utils/attendance_repository.dart';
import '../utils/class_repository.dart';
import '../utils/report_util.dart';
import 'class_picker.dart';

const _presentColor = Color(0xFF10B981);
const _absentColor = Color(0xFFEF4444);
const _warnColor = Color(0xFFF59E0B);

Color _percentColor(double p) =>
    p >= 75 ? _presentColor : (p >= 50 ? _warnColor : _absentColor);

/// Attendance Report: Daily, Monthly and Student-wise tabs.
class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = ClassRepository.visibleToCurrentUser();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AdminUi.bg,
        appBar: AppBar(
          title: const Text('Attendance Report',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          foregroundColor: AdminUi.ink,
          bottom: const TabBar(
            labelColor: AdminUi.blue,
            unselectedLabelColor: AdminUi.muted,
            indicatorColor: AdminUi.blue,
            dividerColor: AdminUi.line,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Monthly'),
              Tab(text: 'Student-wise'),
            ],
          ),
        ),
        body: classes.isEmpty
            ? const AdminEmptyState(
          icon: Icons.insights_outlined,
          title: 'No subjects yet',
          subtitle: 'Add a subject to see reports.',
        )
            : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: TabBarView(children: [
              _DailyReport(classes: classes),
              _MonthlyReport(classes: classes),
              _StudentReport(classes: classes),
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _emptyNote(String text) => AdminEmptyState(
  icon: Icons.insights_outlined,
  title: text,
);

Widget _summaryBox(String label, String value, Color color) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 21, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]),
  ),
);

Widget _pill(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(text,
      style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.w700)),
);

// ───────────────────────────── Daily ─────────────────────────────

class _DailyReport extends StatefulWidget {
  final List<ClassRoom> classes;
  const _DailyReport({required this.classes});

  @override
  State<_DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<_DailyReport> {
  late ClassRoom _class = widget.classes.first;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final saved = AttendanceRepository.get(_class.id, _date);
    final students = ReportUtil.studentsFor(_class)
        .where((s) => saved.containsKey(s.id))
        .toList();
    final present = students.where((s) => saved[s.id] == true).length;
    final absent = students.length - present;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          PickerField(
            label: 'Subject',
            value: classLabel(_class),
            icon: Icons.menu_book_outlined,
            onTap: () async {
              final c = await pickClass(context, widget.classes, _class.id);
              if (c != null) setState(() => _class = c);
            },
          ),
          const SizedBox(height: 12),
          PickerField(
            label: 'Date',
            value: ReportUtil.formatDate(_date),
            icon: Icons.calendar_today_outlined,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          if (students.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              _summaryBox('Present', '$present', _presentColor),
              const SizedBox(width: 8),
              _summaryBox('Absent', '$absent', _absentColor),
              const SizedBox(width: 8),
              _summaryBox('Total', '${students.length}', AdminUi.blue),
            ]),
          ],
        ]),
      ),
      Expanded(
        child: students.isEmpty
            ? _emptyNote('Attendance was not taken for this subject on this date.')
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];
            final isPresent = saved[s.id] == true;
            final color = isPresent ? _presentColor : _absentColor;
            return AdminCard(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AdminUi.ink)),
                      const SizedBox(height: 2),
                      Text('Roll: ${s.rollNumber}',
                          style: const TextStyle(
                              fontSize: 12, color: AdminUi.muted)),
                    ],
                  ),
                ),
                _pill(isPresent ? 'Present' : 'Absent', color),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ──────────────────────────── Monthly ────────────────────────────

class _MonthlyReport extends StatefulWidget {
  final List<ClassRoom> classes;
  const _MonthlyReport({required this.classes});

  @override
  State<_MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<_MonthlyReport> {
  late ClassRoom _class = widget.classes.first;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final (stats, daysTaken) = ReportUtil.monthly(_class, _month);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          PickerField(
            label: 'Subject',
            value: classLabel(_class),
            icon: Icons.menu_book_rounded,
            onTap: () async {
              final c = await pickClass(context, widget.classes, _class.id);
              if (c != null) setState(() => _class = c);
            },
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminUi.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Column(children: [
                  Text(ReportUtil.formatMonth(_month),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('$daysTaken day${daysTaken == 1 ? '' : 's'} taken',
                      style: const TextStyle(
                          fontSize: 12, color: AdminUi.muted)),
                ]),
                IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
        ]),
      ),
      Expanded(
        child: daysTaken == 0
            ? _emptyNote('No attendance recorded for this subject in this month.')
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: stats.length,
          itemBuilder: (_, i) {
            final st = stats[i];
            final color = _percentColor(st.percent);
            return AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(st.student.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AdminUi.ink)),
                    ),
                    _pill('${st.percent.toStringAsFixed(0)}%', color),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                      'Roll: ${st.student.rollNumber}  \u2022  ${st.present} present, ${st.absent} absent',
                      style: const TextStyle(
                          fontSize: 12, color: AdminUi.muted)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (st.percent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ──────────────────────────── Student-wise ────────────────────────────

class _StudentReport extends StatefulWidget {
  final List<ClassRoom> classes;
  const _StudentReport({required this.classes});

  @override
  State<_StudentReport> createState() => _StudentReportState();
}

class _StudentReportState extends State<_StudentReport> {
  late final List<Student> _students = _loadStudents();
  Student? _student;


  static List<Student> _loadStudents() {
    // Only students who belong to at least one of the faculty's subjects.
    final classes = ClassRepository.visibleToCurrentUser();
    final all = <Student>[];
    for (final c in classes) {
      for (final s in ReportUtil.studentsFor(c)) {
        if (!all.any((x) => x.id == s.id)) all.add(s);
      }
    }
    all.sort((a, b) =>
        a.rollNumber.toLowerCase().compareTo(b.rollNumber.toLowerCase()));
    return all;
  }

  Future<void> _pickStudent() async {
    final picked = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(builder: (ctx, setSheet) {
          final shown = _students
              .where((s) =>
          s.name.toLowerCase().contains(query) ||
              s.rollNumber.toLowerCase().contains(query))
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AdminSearchField(
                      hint: 'Search by name or roll number',
                      onChanged: (v) =>
                          setSheet(() => query = v.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: ListView(children: [
                      for (final s in shown)
                        ListTile(
                          title: Text(s.name),
                          subtitle: Text('Roll: ${s.rollNumber}'),
                          onTap: () => Navigator.pop(ctx, s),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );
    if (picked != null) setState(() => _student = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_students.isEmpty) {
      return _emptyNote('No students yet.\nAdd students from My Students first.');
    }
    final stats = _student == null
        ? <StudentClassStat>[]
        : ReportUtil.forStudent(_student!, widget.classes);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: PickerField(
          label: 'Student',
          value: _student == null
              ? 'Select student'
              : '${_student!.name} (${_student!.rollNumber})',
          icon: Icons.person_outline_rounded,
          onTap: _pickStudent,
        ),
      ),
      Expanded(
        child: _student == null
            ? _emptyNote('Select a student to see their attendance.')
            : stats.isEmpty
            ? _emptyNote('This student is not in any of your subjects.')
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: stats.length,
          itemBuilder: (_, i) {
            final st = stats[i];
            final color = _percentColor(st.percent);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminUi.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(classLabel(st.classRoom),
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('${st.present} of ${st.total} days present',
                      style: const TextStyle(
                          fontSize: 12.5, color: AdminUi.muted)),
                  trailing: _pill('${st.percent.toStringAsFixed(0)}%', color),
                  children: [
                    if (st.days.isEmpty)
                      const ListTile(
                          title: Text('No attendance recorded yet.')),
                    for (final e in st.days.entries)
                      ListTile(
                        dense: true,
                        title: Text(
                            ReportUtil.formatDate(DateTime.parse(e.key))),
                        trailing: Text(
                          e.value ? 'Present' : 'Absent',
                          style: TextStyle(
                              color:
                              e.value ? _presentColor : _absentColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}