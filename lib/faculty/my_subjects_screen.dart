import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';

import 'take_attendance_screen.dart';

import '../models/class_room.dart';
import '../utils/attendance_repository.dart';
import '../utils/class_repository.dart';
import '../utils/report_util.dart';
import 'class_picker.dart';
import '../admin/create_class_screen.dart';

/// 📚 My Subjects
/// Shows every class/subject taught by the faculty.
class MySubjectsScreen extends StatefulWidget {
  const MySubjectsScreen({super.key});

  @override
  State<MySubjectsScreen> createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends State<MySubjectsScreen> {
  /// All classes/subjects belonging to the faculty.
  final List<ClassRoom> _classes = ClassRepository.visibleToCurrentUser();

  /// Add a new subject/class.
  Future<void> _addSubject() async {
    final ClassRoom? newClass = await Navigator.push<ClassRoom?>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateClassScreen(),
      ),
    );

    if (!mounted || newClass == null) {
      return;
    }

    setState(() {
      _classes.add(newClass);
    });

    await ClassRepository.add(newClass);
  }

  /// Confirm and delete a subject.
  Future<void> _confirmDelete(ClassRoom classroom) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Delete subject?',
      message: 'Delete "${classroom.name}" and all of its attendance '
          'records? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    await ClassRepository.delete(_classes, classroom.id);
    if (!mounted) return;
    setState(() {});
  }

  /// Open attendance screen for a selected subject.
  Future<void> _openAttendance(ClassRoom classroom) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TakeAttendanceScreen(
          initialClass: classroom,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('My Subjects'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubject,
        backgroundColor: AdminUi.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add subject'),
      ),
      body: _classes.isEmpty
          ? const AdminEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No subjects yet',
        subtitle: 'Tap "Add subject" to create your first subject.',
      )
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _classes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return AdminListHeader(
                    '${_classes.length} subject${_classes.length == 1 ? '' : 's'}');
              }
              final classroom = _classes[index - 1];
              return _buildSubjectCard(
                classroom: classroom,
                students: ReportUtil.studentsFor(classroom).length,
                taken: AttendanceRepository.daysTaken(classroom.id),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AdminUi.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 11.5, color: AdminUi.muted)),
        ),
      ],
    ),
  );

  /// Subject card.
  Widget _buildSubjectCard({
    required ClassRoom classroom,
    required int students,
    required int taken,
  }) {
    return AdminCard(
      onTap: () => _openAttendance(classroom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AdminUi.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AdminUi.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classLabel(classroom),
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AdminUi.ink),
                ),
                const SizedBox(height: 2),
                Text(classroom.name,
                    style:
                    const TextStyle(fontSize: 13, color: AdminUi.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.schedule_rounded,
                        '${classroom.days.join(', ')} ${classroom.startTime.format(context)}'),
                    _chip(Icons.people_outline_rounded,
                        '$students student${students == 1 ? '' : 's'}'),
                    _chip(Icons.event_available_outlined,
                        '$taken day${taken == 1 ? '' : 's'} taken'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const Icon(Icons.more_vert_rounded, color: AdminUi.muted),
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(classroom);
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 19, color: AdminUi.danger),
                    SizedBox(width: 10),
                    Text('Delete subject'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}