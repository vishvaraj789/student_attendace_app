import 'package:flutter/material.dart';
import '../login_page.dart';
import 'student_data.dart';

/// 👤 Profile: who is logged in, quick totals and log out.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

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

  Widget _row(IconData icon, String label, String value,
      {Color color = AdminUi.blue, Color? valueColor}) {
    return AdminCard(
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
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AdminUi.ink)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AdminUi.ink)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = StudentData.load();
    final me = d.me;
    final name = d.name;

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: studentAppBar('Profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              AdminCard(
                padding:
                const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AdminUi.ink)),
                    if (d.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(d.email,
                          style: const TextStyle(
                              color: AdminUi.muted, fontSize: 14)),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AdminUi.blue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Student',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AdminUi.blue)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const AdminListHeader('Details'),
              _row(Icons.badge_outlined, 'Roll number', me?.rollNumber ?? '-'),
              _row(Icons.groups_outlined, 'Division',
                  (me?.division.isEmpty ?? true) ? '-' : me!.division,
                  color: const Color(0xFF8B5CF6)),
              _row(Icons.menu_book_rounded, 'Subjects', '${d.subjects.length}',
                  color: const Color(0xFF0EA5E9)),
              _row(
                Icons.percent_rounded,
                'Overall attendance',
                d.hasData ? '${d.overallPercent.toStringAsFixed(1)}%' : '--',
                color: percentColor(d.overallPercent, hasData: d.hasData),
                valueColor: percentColor(d.overallPercent, hasData: d.hasData),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AdminUi.danger),
                label: const Text('Log out',
                    style: TextStyle(
                        color: AdminUi.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AdminUi.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}