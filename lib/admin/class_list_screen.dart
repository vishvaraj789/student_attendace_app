import 'package:flutter/material.dart';
import 'create_class_screen.dart';
import '../models/class_room.dart';
import '../utils/attendance_repository.dart';
import '../models/faculty.dart';
import '../utils/class_repository.dart';
import '../utils/faculty_repository.dart';
import '../utils/login_share.dart';
import 'admin_ui.dart';

/// Admin: create and manage classes. Every class is a division + subject
/// pair, and the list is grouped by division.
class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final List<ClassRoom> _classes = ClassRepository.getAll();
  String _query = '';

  Future<void> _create() async {
    final created = await Navigator.push<ClassRoom>(
      context,
      MaterialPageRoute(builder: (_) => const CreateClassScreen()),
    );
    if (created == null || !mounted) return;

    // One class per division + subject.
    final exists = _classes.any((c) =>
    c.division.toLowerCase() == created.division.toLowerCase() &&
        c.subject.toLowerCase() == created.subject.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${created.subject} already exists for ${created.divisionLabel}'),
        ),
      );
      return;
    }

    setState(() => _classes.add(created));
    await ClassRepository.saveAll(_classes);
  }

  Future<void> _confirmDelete(ClassRoom c) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Delete class?',
      message:
      'Delete "${c.name}" and all of its attendance records? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    await ClassRepository.delete(_classes, c.id);
    if (mounted) setState(() {});
  }

  /// division label -> classes, divisions sorted, "All divisions" last.
  Map<String, List<ClassRoom>> _grouped() {
    final map = <String, List<ClassRoom>>{};
    final q = _query.trim().toLowerCase();
    for (final c in _classes) {
      if (q.isNotEmpty &&
          !c.subject.toLowerCase().contains(q) &&
          !c.name.toLowerCase().contains(q) &&
          !c.divisionLabel.toLowerCase().contains(q)) {
        continue;
      }
      map.putIfAbsent(c.divisionLabel, () => []).add(c);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'All divisions') return 1;
        if (b == 'All divisions') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return {
      for (final k in keys)
        k: (map[k]!..sort((a, b) =>
            a.subject.toLowerCase().compareTo(b.subject.toLowerCase()))),
    };
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Classes'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AdminUi.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create class'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: AdminSearchField(
                  hint: 'Search by subject, class or division',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? AdminEmptyState(
                  icon: Icons.class_outlined,
                  title: _classes.isEmpty
                      ? 'No classes yet'
                      : 'No classes found',
                  subtitle: _classes.isEmpty
                      ? 'Tap "Create class" to add a subject for a division.'
                      : 'Try a different search.',
                )
                    : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    for (final entry in groups.entries) ...[
                      _divisionHeader(entry.key, entry.value.length),
                      for (final c in entry.value) _buildTile(c),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Faculty? _facultyOf(ClassRoom c) {
    if (c.facultyId.isEmpty) return null;
    for (final f in FacultyRepository.getAll()) {
      if (f.id == c.facultyId) return f;
    }
    return null;
  }

  /// Pick the faculty who will take attendance for this class.
  Future<void> _assign(ClassRoom c) async {
    final faculty = FacultyRepository.getAll();
    if (faculty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a faculty member first')),
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text('Assign "${c.subject}" to',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.ink)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Text(
                'The faculty will see this class on their home screen and can take attendance in one tap.',
                style: TextStyle(fontSize: 12.5, color: AdminUi.muted),
              ),
            ),
            for (final f in faculty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: f.id == c.facultyId
                      ? AdminUi.blue.withValues(alpha: 0.07)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    f.id == c.facultyId ? AdminUi.blue : AdminUi.line,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: AdminAvatar(
                    text: f.name,
                    colors: const [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  title: Text(f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(f.email,
                      style: const TextStyle(
                          fontSize: 12.5, color: AdminUi.muted)),
                  trailing: f.id == c.facultyId
                      ? const Icon(Icons.check_circle_rounded,
                      color: AdminUi.blue)
                      : null,
                  onTap: () => Navigator.pop(ctx, f.id),
                ),
              ),
            if (c.facultyId.isNotEmpty)
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, ''),
                icon: const Icon(Icons.person_remove_alt_1_outlined),
                label: const Text('Remove assignment'),
                style: TextButton.styleFrom(foregroundColor: AdminUi.danger),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;

    final i = _classes.indexWhere((x) => x.id == c.id);
    if (i == -1) return;
    final updated = c.copyWith(facultyId: picked);
    setState(() => _classes[i] = updated);
    await ClassRepository.saveAll(_classes);
    if (!mounted) return;

    final who = _facultyOf(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(who == null
            ? 'Assignment removed'
            : '"${updated.subject}" assigned to ${who.name}'),
        action: who == null
            ? null
            : SnackBarAction(
          label: 'Share',
          onPressed: () => _shareAssignment(updated),
        ),
      ),
    );
  }

  /// Send the faculty a message about the class they were given.
  void _shareAssignment(ClassRoom c) {
    final f = _facultyOf(c);
    if (f == null) return;
    LoginShare.shareText(
      context,
      LoginShare.classAssignmentMessage(
        facultyName: f.name,
        subject: c.subject,
        className: c.name,
        division: c.divisionLabel,
        schedule: '${c.days.join(', ')} ${c.startTime.format(context)}',
      ),
      subject: 'Class assigned: ${c.subject}',
    );
  }

  Widget _divisionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AdminUi.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count class${count == 1 ? '' : 'es'}',
            style: const TextStyle(fontSize: 12.5, color: AdminUi.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(ClassRoom c) {
    final taken = AttendanceRepository.daysTaken(c.id);
    return AdminCard(
      child: Row(
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
                  c.subject,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AdminUi.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.name}  \u2022  ${c.divisionLabel}',
                  style: const TextStyle(fontSize: 13, color: AdminUi.muted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.schedule_rounded,
                        '${c.days.join(', ')} ${c.startTime.format(context)}'),
                    _chip(Icons.event_available_outlined,
                        '$taken day${taken == 1 ? '' : 's'} taken'),
                    _facultyChip(c),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const Icon(Icons.more_vert_rounded, color: AdminUi.muted),
            onSelected: (v) {
              if (v == 'assign') _assign(c);
              if (v == 'share') _shareAssignment(c);
              if (v == 'delete') _confirmDelete(c);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'assign',
                child: Row(children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      size: 19, color: AdminUi.blue),
                  SizedBox(width: 10),
                  Text('Assign faculty'),
                ]),
              ),
              if (c.facultyId.isNotEmpty)
                const PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    Icon(Icons.share_outlined,
                        size: 19, color: Color(0xFF059669)),
                    SizedBox(width: 10),
                    Text('Share with faculty'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 19, color: AdminUi.danger),
                  SizedBox(width: 10),
                  Text('Delete class'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _facultyChip(ClassRoom c) {
    final f = _facultyOf(c);
    final assigned = f != null;
    final color = assigned ? const Color(0xFF059669) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(assigned ? Icons.person_rounded : Icons.person_off_outlined,
              size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              assigned ? f.name : 'Not assigned',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
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
}