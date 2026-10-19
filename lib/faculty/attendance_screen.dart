import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/class_room.dart';
import '../models/student.dart';
import '../utils/attendance_repository.dart';
import '../utils/student_repository.dart';

class AttendanceScreen extends StatefulWidget {
  final ClassRoom classRoom;

  const AttendanceScreen({required this.classRoom, super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _accent = AdminUi.blue;
  static const _presentColor = Color(0xFF10B981);
  static const _absentColor = Color(0xFFEF4444);

  late List<Student> _students;
  DateTime _date = DateTime.now();
  Map<String, bool> _status = {}; // studentId -> true = present
  bool _alreadySaved = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _students = StudentRepository.getAll()
        .where((s) => widget.classRoom.includesDivision(s.division))
        .toList()
      ..sort((a, b) {
        final byRoll = a.rollNumber.toLowerCase().compareTo(b.rollNumber.toLowerCase());
        return byRoll != 0 ? byRoll : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    _loadDay();
  }

  /// Loads saved attendance for the selected date. Students with no saved
  /// entry (new students, or a day not taken yet) default to Present.
  void _loadDay() {
    final saved = AttendanceRepository.get(widget.classRoom.id, _date);
    _status = {for (final s in _students) s.id: saved[s.id] ?? true};
    _alreadySaved = saved.isNotEmpty;
    _dirty = false;
  }

  int get _presentCount => _status.values.where((v) => v).length;
  int get _absentCount => _status.values.where((v) => !v).length;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _loadDay();
      });
    }
  }

  void _setAll(bool present) {
    setState(() {
      for (final s in _students) {
        _status[s.id] = present;
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    await AttendanceRepository.save(widget.classRoom.id, _date, _status);
    if (!mounted) return;
    setState(() {
      _alreadySaved = true;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance saved: $_presentCount present, $_absentCount absent',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
      child: Row(
        children: [
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classRoom;
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar(c.name),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminUi.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [c.subject, c.divisionLabel]
                                  .where((e) => e.isNotEmpty)
                                  .join(' \u2022 '),
                              style: const TextStyle(
                                  color: AdminUi.muted, fontSize: 14),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            label: Text(_formatDate(_date)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminUi.ink,
                              side: const BorderSide(color: AdminUi.line),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _CountBox(
                              label: 'Present',
                              value: _presentCount,
                              color: _presentColor),
                          const SizedBox(width: 8),
                          _CountBox(
                              label: 'Absent',
                              value: _absentCount,
                              color: _absentColor),
                          const SizedBox(width: 8),
                          _CountBox(
                              label: 'Total',
                              value: _students.length,
                              color: _accent),
                        ],
                      ),
                      if (_alreadySaved) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15, color: AdminUi.muted),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Already saved for this date. Changes will overwrite it.',
                                style: TextStyle(
                                    fontSize: 12, color: AdminUi.muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
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
                    ],
                  ),
                ),
              Expanded(
                child: _students.isEmpty
                    ? AdminEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No students yet',
                  subtitle: widget.classRoom.division.isEmpty
                      ? 'Add students from the Student List first.'
                      : 'No students in Division ${widget.classRoom.division} yet. Add students to this division first.',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _students.length,
                  itemBuilder: (context, i) => _studentRow(_students[i]),
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
                onPressed: (_dirty || !_alreadySaved) ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _alreadySaved ? 'Update attendance' : 'Save attendance',
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

  const _CountBox({
    required this.label,
    required this.value,
    required this.color,
  });

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
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}