import 'package:flutter/material.dart';
import '../faculty/attendance_report_screen.dart';
import '../faculty/student_list_screen.dart';
import '../faculty/take_attendance_screen.dart';
import '../login_page.dart';
import '../utils/admin_auth.dart';
import '../utils/class_repository.dart';
import '../utils/faculty_repository.dart';
import '../utils/student_repository.dart';
import 'admin_settings_screen.dart';
import 'admin_ui.dart';
import 'class_list_screen.dart';
import 'faculty_list_screen.dart';

/// Admin panel: manage faculty and students (and their logins).
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const _navy = Color(0xFF0F1F3D);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF3F5F9);

  int _facultyCount = FacultyRepository.getAll().length;
  int _studentCount = StudentRepository.count();
  int _classCount = ClassRepository.getAll().length;

  void _refresh() {
    setState(() {
      _facultyCount = FacultyRepository.getAll().length;
      _studentCount = StudentRepository.count();
      _classCount = ClassRepository.getAll().length;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  Future<void> _logout() async {
    final ok = await showAdminConfirm(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to log out of the admin panel?',
      confirmLabel: 'Log out',
    );
    if (!ok || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  void _changePassword() {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const AdminDialogHeader(
          icon: Icons.lock_reset_rounded,
          title: 'Change password',
          subtitle: 'Update the admin password',
          color: AdminUi.danger,
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: adminInputDecoration(
                      'Current password', Icons.lock_outline_rounded),
                  validator: (v) => v == null || !AdminAuth.isCurrentPassword(v)
                      ? 'Current password is wrong'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  decoration: adminInputDecoration(
                      'New password', Icons.key_rounded),
                  validator: (v) => v == null || v.length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  decoration: adminInputDecoration(
                      'Confirm new password', Icons.verified_user_outlined),
                  validator: (v) =>
                  v != next.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await AdminAuth.changePassword(next.text);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin password updated')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AdminUi.blue,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _today() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = DateTime.now();
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _banner() {
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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFFBFDBFE)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AdminAuth.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFDBEAFE)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _today(),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: _ink,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.fact_check_outlined,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin Panel',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, color: _muted),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
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
                _banner(),
                const SizedBox(height: 24),
                const Text(
                  'Quick access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
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
                        _Tile(
                          icon: Icons.badge_rounded,
                          title: 'Faculty',
                          count: _facultyCount,
                          colors: const [Color(0xFF10B981), Color(0xFF047857)],
                          onTap: () => _open(const FacultyListScreen()),
                        ),
                        _Tile(
                          icon: Icons.school_rounded,
                          title: 'Students',
                          count: _studentCount,
                          colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          onTap: () => _open(const StudentListScreen()),
                        ),
                        _Tile(
                          icon: Icons.class_rounded,
                          title: 'Classes',
                          count: _classCount,
                          colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          onTap: () => _open(const ClassListScreen()),
                        ),
                        _Tile(
                          icon: Icons.fact_check_rounded,
                          title: 'Attendance',
                          caption: 'Take or edit attendance',
                          colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          onTap: () => _open(const TakeAttendanceScreen()),
                        ),
                        _Tile(
                          icon: Icons.insights_rounded,
                          title: 'Reports',
                          caption: 'Daily, monthly, student-wise',
                          colors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
                          onTap: () => _open(const AttendanceReportScreen()),
                        ),
                        _Tile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          caption: 'Password, sync, log out',
                          colors: const [Color(0xFF475569), Color(0xFF1E293B)],
                          onTap: () => _open(AdminSettingsScreen(
                            onChangePassword: _changePassword,
                            onLogout: _logout,
                          )),
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

/// Big colorful button used on the admin home grid.
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final String? caption;
  final List<Color> colors;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.colors,
    required this.onTap,
    this.count,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // soft decorative circles
                Positioned(
                  right: -26,
                  top: -26,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: -34,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      if (count != null)
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      if (count != null) const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          caption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}