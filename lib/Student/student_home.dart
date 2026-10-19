import 'package:flutter/material.dart';
import 'student_data.dart';
import 'student_history_screen.dart';
import 'student_notifications_screen.dart';
import 'student_profile_screen.dart';
import 'student_report_screen.dart';
import 'student_subjects_screen.dart';

/// Student Dashboard: percentage up top, then the five sections.
/// Read-only: students can only see their own attendance.
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  late StudentData _data = StudentData.load();

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => setState(() => _data = StudentData.load()));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _banner(StudentData d) {
    final info = d.me == null
        ? 'Your attendance record'
        : 'Roll No: ${d.me!.rollNumber}'
        '${d.me!.division.isEmpty ? '' : '  •  Division ${d.me!.division}'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1F3D), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              d.name.isEmpty ? '?' : d.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFFBFDBFE))),
                const SizedBox(height: 2),
                Text(d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(info,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFDBEAFE))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final alerts = buildNotifications(d).length;

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
            const Text('Student Dashboard',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AdminUi.muted),
            onPressed: () => setState(() => _data = StudentData.load()),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminUi.line),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _data = StudentData.load()),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                _banner(d),
                const SizedBox(height: 20),
                if (d.me == null)
                  EmptyState(
                    icon: Icons.person_search_outlined,
                    title: "You're not in the student list",
                    message: 'No student with the email "${d.email}" was found. '
                        'Ask your faculty to add you using this email.',
                  )
                else ...[
                  _PercentageCard(data: d),
                  const SizedBox(height: 24),
                  const Text('Quick access',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AdminUi.ink)),
                  const SizedBox(height: 14),
                  _Tile(
                    icon: Icons.calendar_month_rounded,
                    color: AdminUi.blue,
                    title: 'Attendance History',
                    subtitle: d.hasData
                        ? '${d.totalClasses} records'
                        : 'No records yet',
                    onTap: () => _open(const StudentHistoryScreen()),
                  ),
                  _Tile(
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF0EA5E9),
                    title: 'Subjects',
                    subtitle: '${d.subjects.length} subjects',
                    onTap: () => _open(const StudentSubjectsScreen()),
                  ),
                  _Tile(
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Attendance Report',
                    subtitle: 'Subject-wise analysis',
                    onTap: () => _open(const StudentReportScreen()),
                  ),
                  _Tile(
                    icon: Icons.notifications_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Notifications',
                    subtitle: alerts == 0 ? 'All clear' : '$alerts new',
                    badge: alerts,
                    onTap: () => _open(const StudentNotificationsScreen()),
                  ),
                  _Tile(
                    icon: Icons.person_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Profile',
                    subtitle: d.name,
                    onTap: () => _open(const StudentProfileScreen()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PercentageCard extends StatelessWidget {
  final StudentData data;
  const _PercentageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = percentColor(data.overallPercent, hasData: data.hasData);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: data.hasData ? data.overallPercent / 100 : 0,
                    strokeWidth: 9,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  data.hasData
                      ? '${data.overallPercent.toStringAsFixed(0)}%'
                      : '--',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Percentage',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  data.hasData
                      ? '${data.totalPresent} present  •  ${data.totalAbsent} absent'
                      : 'No attendance taken yet',
                  style: const TextStyle(color: AdminUi.muted, fontSize: 13),
                ),
                if (data.hasData && data.overallPercent < kMinPercent) ...[
                  const SizedBox(height: 6),
                  Text('Below ${kMinPercent.toStringAsFixed(0)}% requirement',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AdminUi.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: AdminUi.muted)),
              ],
            ),
          ),
          if (badge > 0)
            Badge(label: Text('$badge'), backgroundColor: AdminUi.danger),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AdminUi.muted),
        ],
      ),
    );
  }
}