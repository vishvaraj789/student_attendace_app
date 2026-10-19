import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../login_page.dart';
import '../utils/class_repository.dart';
import '../utils/shared_preference.dart';
import '../utils/student_repository.dart';

/// Profile: who is logged in, quick totals and log out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
    );
    if (!ok || !context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Widget _statBox(IconData icon, Color color, String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminUi.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AdminUi.ink,
                        height: 1)),
                const SizedBox(height: 3),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AdminUi.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = SharedPrefsUtil.getString('user_name', defaultValue: 'Faculty');
    final email = SharedPrefsUtil.getString('user_email');
    final subjects = ClassRepository.visibleToCurrentUser().length;
    final students = StudentRepository.count();

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppBanner(
                icon: Icons.person_rounded,
                greeting: 'Signed in as',
                name: name,
                line: email,
                chip: 'Faculty',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _statBox(Icons.menu_book_rounded, const Color(0xFF2563EB),
                      'Subjects', subjects),
                  const SizedBox(width: 12),
                  _statBox(Icons.school_rounded, const Color(0xFFD97706),
                      'Students', students),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminUi.danger,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}