import 'package:flutter/material.dart';
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
  static const _accent = Color(0xFF6366F1);
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

  @override
  Widget build(BuildContext context) {
    final c = widget.classRoom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          c.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                              .join(' • '),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_formatDate(_date)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                    Text(
                      'Attendance already saved for this date. Changes will overwrite it.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _setAll(true),
                    child: const Text('Mark all present'),
                  ),
                  TextButton(
                    onPressed: () => _setAll(false),
                    child: const Text('Mark all absent'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _students.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.classRoom.division.isEmpty
                      ? 'No students yet.\nAdd students from the Student List first.'
                      : 'No students in Division ${widget.classRoom.division} yet.\nAdd students to this division first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              itemBuilder: (context, i) {
                final s = _students[i];
                final present = _status[s.id] ?? true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (present ? _presentColor : _absentColor)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll: ${s.rollNumber}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('P'),
                        selected: present,
                        selectedColor:
                        _presentColor.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() {
                          _status[s.id] = true;
                          _dirty = true;
                        }),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('A'),
                        selected: !present,
                        selectedColor:
                        _absentColor.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() {
                          _status[s.id] = false;
                          _dirty = true;
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _students.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_dirty || !_alreadySaved) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _alreadySaved ? 'Update Attendance' : 'Save Attendance',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}