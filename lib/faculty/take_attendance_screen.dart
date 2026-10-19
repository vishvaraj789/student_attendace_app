import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/class_room.dart';
import '../models/student.dart';
import '../utils/attendance_repository.dart';
import '../utils/class_repository.dart';
import '../utils/report_util.dart';
import 'class_picker.dart';

/// ✅ Take Attendance: Select Subject → Select Date → Present/Absent → Submit.
class TakeAttendanceScreen extends StatefulWidget {
  final ClassRoom? initialClass;

  const TakeAttendanceScreen({this.initialClass, super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  static const _accent = AdminUi.blue;
  static const _presentColor = Color(0xFF10B981);
  static const _absentColor = Color(0xFFEF4444);

  final List<ClassRoom> _classes = ClassRepository.visibleToCurrentUser();
  ClassRoom? _class;
  DateTime _date = DateTime.now();
  List<Student> _students = [];
  Map<String, bool> _status = {}; // studentId -> true = present
  bool _alreadySaved = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialClass != null) {
      _class = widget.initialClass;
    } else if (_classes.length == 1) {
      _class = _classes.first;
    }
    _load();
  }

  /// Loads the students of the selected subject and any attendance already
  /// saved for the selected date (default for everyone else: Present).
  void _load() {
    final c = _class;
    if (c == null) {
      _students = [];
      _status = {};
      _alreadySaved = false;
      _dirty = false;
      return;
    }
    _students = ReportUtil.studentsFor(c);
    final saved = AttendanceRepository.get(c.id, _date);
    _status = {for (final s in _students) s.id: saved[s.id] ?? true};
    _alreadySaved = saved.isNotEmpty;
    _dirty = false;
  }

  int get _present => _status.values.where((v) => v).length;
  int get _absent => _status.values.where((v) => !v).length;

  Future<void> _selectSubject() async {
    final picked = await pickClass(context, _classes, _class?.id);
    if (picked != null) setState(() {
      _class = picked;
      _load();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() {
      _date = picked;
      _load();
    });
  }

  void _setAll(bool present) {
    setState(() {
      for (final s in _students) {
        _status[s.id] = present;
      }
      _dirty = true;
    });
  }

  Future<void> _submit() async {
    final c = _class;
    if (c == null) return;
    await AttendanceRepository.save(c.id, _date, _status);
    if (!mounted) return;
    setState(() {
      _alreadySaved = true;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Attendance submitted: $_present present, $_absent absent'),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _toggle(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AdminUi.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AdminUi.muted,
          ),
        ),
      ),
    );
  }

  Widget _studentRow(Student s) {
    final present = _status[s.id] ?? true;
    final color = present ? _presentColor : _absentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
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
                fontSize: 17, fontWeight: FontWeight.w700, color: color),
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
                  style:
                  const TextStyle(fontSize: 12, color: AdminUi.muted)),
            ],
          ),
        ),
        _toggle('P', present, _presentColor, () => setState(() {
          _status[s.id] = true;
          _dirty = true;
        })),
        const SizedBox(width: 6),
        _toggle('A', !present, _absentColor, () => setState(() {
          _status[s.id] = false;
          _dirty = true;
        })),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Take Attendance'),
      body: _classes.isEmpty
          ? const AdminEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No subjects yet',
        subtitle: 'Add a subject from My Subjects first.',
      )
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    PickerField(
                      label: 'Subject',
                      value: _class == null
                          ? 'Select subject'
                          : classLabel(_class!),
                      icon: Icons.menu_book_outlined,
                      onTap: _selectSubject,
                    ),
                    const SizedBox(height: 12),
                    PickerField(
                      label: 'Date',
                      value: ReportUtil.formatDate(_date),
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectDate,
                    ),
                    if (_class != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        _CountBox('Present', _present, _presentColor),
                        const SizedBox(width: 8),
                        _CountBox('Absent', _absent, _absentColor),
                        const SizedBox(width: 8),
                        _CountBox('Total', _students.length, _accent),
                      ]),
                      if (_alreadySaved)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline_rounded,
                                  size: 15, color: AdminUi.muted),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Already submitted for this date. Submitting again will overwrite it.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AdminUi.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (_students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    TextButton.icon(
                      onPressed: () => _setAll(true),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('All present'),
                      style: TextButton.styleFrom(
                          foregroundColor: _presentColor),
                    ),
                    TextButton.icon(
                      onPressed: () => _setAll(false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('All absent'),
                      style: TextButton.styleFrom(
                          foregroundColor: _absentColor),
                    ),
                  ]),
                ),
              Expanded(
                child: _class == null
                    ? const AdminEmptyState(
                    icon: Icons.touch_app_outlined,
                    title: 'Select a subject to begin')
                    : _students.isEmpty
                    ? const AdminEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No students in this subject yet',
                  subtitle:
                  'Add students from My Students first.',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 4, 16, 16),
                  itemCount: _students.length,
                  itemBuilder: (_, i) =>
                      _studentRow(_students[i]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _students.isEmpty
          ? null
          : Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AdminUi.line)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: (_dirty || !_alreadySaved) ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _alreadySaved
                      ? 'Update attendance'
                      : 'Submit attendance',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ]),
      ),
    );
  }
}