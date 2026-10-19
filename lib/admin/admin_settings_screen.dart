import 'package:flutter/material.dart';
import '../utils/admin_auth.dart';
import '../utils/cloud_sync.dart';

/// Admin settings: account, data sync and log out.
class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const AdminSettingsScreen({
    required this.onChangePassword,
    required this.onLogout,
    super.key,
  });

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const _navy = Color(0xFF0F1F3D);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF3F5F9);

  bool _syncing = false;

  Future<void> _syncNow() async {
    if (!CloudSync.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sheets is not set up yet (sheets_config.dart)'),
        ),
      );
      return;
    }
    setState(() => _syncing = true);
    await CloudSync.pullAll();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(CloudSync.status)),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _muted,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(children: children),
      ),
    ],
  );

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool divider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle,
              style: const TextStyle(fontSize: 12.5, color: _muted)),
          trailing: trailing ??
              (onTap == null
                  ? null
                  : const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF))),
        ),
        if (divider)
          const Divider(height: 1, indent: 70, color: Color(0xFFF0F1F4)),
      ],
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
        title: const Text('Settings',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _section('Account', [
                _row(
                  icon: Icons.admin_panel_settings_outlined,
                  color: _navy,
                  title: 'Administrator',
                  subtitle: AdminAuth.email,
                ),
                _row(
                  icon: Icons.lock_reset_rounded,
                  color: const Color(0xFFDC2626),
                  title: 'Change password',
                  subtitle: 'Update the admin password',
                  onTap: widget.onChangePassword,
                  divider: false,
                ),
              ]),
              _section('Data', [
                _row(
                  icon: Icons.cloud_sync_outlined,
                  color: const Color(0xFF2563EB),
                  title: 'Sync with Google Sheets',
                  subtitle: CloudSync.isReady
                      ? 'Tap to refresh data from the Sheet'
                      : 'Not set up yet',
                  trailing: _syncing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                      : const Icon(Icons.refresh_rounded, color: _muted),
                  onTap: _syncing ? null : _syncNow,
                  divider: false,
                ),
              ]),
              _section('About', [
                _row(
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFF059669),
                  title: 'Attendance Management System',
                  subtitle: 'Version 1.0',
                  divider: false,
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
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