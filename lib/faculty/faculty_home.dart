import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/class_room.dart';
import '../utils/class_repository.dart';
import '../utils/shared_preference.dart';
import '../utils/student_repository.dart';
import 'attendance_report_screen.dart';
import 'class_picker.dart';
import 'my_subjects_screen.dart';
import 'profile_screen.dart';
import 'student_list_screen.dart';
import 'take_attendance_screen.dart';

/// Faculty dashboard: banner + a grid of big buttons.
///  - My Subjects, My Students, Take Attendance, Reports, Profile
class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  int _subjectCount = ClassRepository.visibleToCurrentUser().length;
  int _studentCount = StudentRepository.count();

  /// Classes the admin assigned to the logged-in faculty.
  List<ClassRoom> _assigned() =>
      ClassRepository.assignedTo(SharedPrefsUtil.getString('user_id'));

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _assignedCard(ClassRoom c) {
    final today = _dayNames[DateTime.now().weekday - 1];
    final isToday = c.days.contains(today);
    return AdminCard(
      onTap: () => _open(TakeAttendanceScreen(initialClass: c)),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        classLabel(c),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AdminUi.ink),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Today',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${c.days.join(', ')} ${c.startTime.format(context)}',
                  style: const TextStyle(fontSize: 12.5, color: AdminUi.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _open(TakeAttendanceScreen(initialClass: c)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Take\nattendance',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.15)),
          ),
        ],
      ),
    );
  }

  /// Opens a screen and refreshes the numbers when coming back.
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(() {
      _subjectCount = ClassRepository.visibleToCurrentUser().length;
      _studentCount = StudentRepository.count();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = SharedPrefsUtil.getString('user_name', defaultValue: 'Faculty');
    final email = SharedPrefsUtil.getString('user_email');

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: AdminUi.ink,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AdminUi.navy,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.fact_check_outlined,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            const Text(
              'Faculty',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined,
                color: AdminUi.muted),
            onPressed: () => _open(const ProfileScreen()),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminUi.line),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBanner(
                  icon: Icons.person_rounded,
                  greeting: greetingForNow(),
                  name: name,
                  line: email,
                  chip: 'Faculty',
                ),
                if (_assigned().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'My classes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Assigned to you by the admin. Tap to take attendance.',
                    style: TextStyle(fontSize: 13, color: AdminUi.muted),
                  ),
                  const SizedBox(height: 12),
                  for (final c in _assigned()) _assignedCard(c),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Quick access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.ink,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= 700 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.0,
                      children: [
                        AppTile(
                          icon: Icons.menu_book_rounded,
                          title: 'My Subjects',
                          count: _subjectCount,
                          colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          onTap: () => _open(const MySubjectsScreen()),
                        ),
                        AppTile(
                          icon: Icons.school_rounded,
                          title: 'My Students',
                          count: _studentCount,
                          colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          onTap: () => _open(const StudentListScreen()),
                        ),
                        AppTile(
                          icon: Icons.fact_check_rounded,
                          title: 'Take Attendance',
                          caption: 'Pick a subject and date',
                          colors: const [Color(0xFF10B981), Color(0xFF047857)],
                          onTap: () => _open(const TakeAttendanceScreen()),
                        ),
                        AppTile(
                          icon: Icons.insights_rounded,
                          title: 'Reports',
                          caption: 'Daily, monthly, student-wise',
                          colors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
                          onTap: () => _open(const AttendanceReportScreen()),
                        ),
                        AppTile(
                          icon: Icons.person_rounded,
                          title: 'Profile',
                          caption: 'Your details and log out',
                          colors: const [Color(0xFF475569), Color(0xFF1E293B)],
                          onTap: () => _open(const ProfileScreen()),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}