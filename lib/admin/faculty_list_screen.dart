import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../faculty/student_list_screen.dart' show generatePassword;
import '../models/faculty.dart';
import '../utils/admin_auth.dart';
import '../utils/class_repository.dart';
import '../utils/faculty_repository.dart';
import '../utils/login_share.dart';
import 'admin_ui.dart';

/// Admin screen: add, view, edit and delete faculty accounts.
class FacultyListScreen extends StatefulWidget {
  const FacultyListScreen({super.key});

  @override
  State<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen> {
  late List<Faculty> _faculty;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _faculty = FacultyRepository.getAll();
  }

  List<Faculty> get _filtered {
    if (_query.isEmpty) return _faculty;
    final q = _query.toLowerCase();
    return _faculty
        .where((f) =>
    f.name.toLowerCase().contains(q) ||
        f.email.toLowerCase().contains(q))
        .toList();
  }

  String? _emailTaken(String email, {String? excludeId}) {
    if (email.toLowerCase() == AdminAuth.email.toLowerCase()) {
      return 'This email is used by the admin account';
    }
    for (final f in _faculty) {
      if (f.id == excludeId) continue;
      if (f.email.toLowerCase() == email.toLowerCase()) {
        return 'A faculty with this email already exists';
      }
    }
    return null;
  }

  void _showForm({Faculty? faculty}) {
    showDialog(
      context: context,
      builder: (_) => _FacultyDialog(
        faculty: faculty,
        onSave: (name, email, password) {
          final error = _emailTaken(email, excludeId: faculty?.id);
          if (error != null) return error;
          setState(() {
            if (faculty == null) {
              _faculty.add(Faculty(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                email: email,
                password: password,
              ));
            } else {
              final i = _faculty.indexWhere((f) => f.id == faculty.id);
              if (i != -1) {
                _faculty[i] = faculty.copyWith(
                    name: name, email: email, password: password);
              }
            }
          });
          FacultyRepository.saveAll(_faculty);
          return null;
        },
      ),
    );
  }

  void _shareLogin(Faculty f) {
    LoginShare.share(
      context,
      name: f.name,
      role: 'Faculty',
      email: f.email,
      password: f.password,
    );
  }

  void _showCredentials(Faculty f) {
    showDialog(
      context: context,
      builder: (ctx) {
        void copy(String label, String text) {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('$label copied'),
            duration: const Duration(seconds: 1),
          ));
        }

        Widget row(String label, String value, IconData icon) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminUi.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AdminUi.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, color: AdminUi.muted)),
                    const SizedBox(height: 2),
                    SelectableText(value,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => copy(label, value),
              ),
            ],
          ),
        );

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: AdminDialogHeader(
            icon: Icons.vpn_key_rounded,
            title: 'Login details',
            subtitle: f.name,
            color: const Color(0xFFD97706),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Email', f.email, Icons.mail_outline_rounded),
              row('Password', f.password, Icons.lock_outline_rounded),
              const SizedBox(height: 2),
              const Text(
                'Give these to the faculty. They sign in with the same login page.',
                style: TextStyle(fontSize: 12.5, color: AdminUi.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => copy('Login details',
                  'Email: ${f.email}\nPassword: ${f.password}'),
              child: const Text('Copy'),
            ),
            TextButton.icon(
              onPressed: () => _shareLogin(f),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AdminUi.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(Faculty f) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Delete faculty?',
      message:
      'Delete ${f.name}? They will no longer be able to log in. This cannot be undone.',
    );
    if (!ok || !mounted) return;
    setState(() => _faculty.removeWhere((x) => x.id == f.id));
    FacultyRepository.saveAll(_faculty);
    await ClassRepository.unassignFaculty(f.id);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Faculty'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AdminUi.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add faculty'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: AdminSearchField(
                  hint: 'Search by name or email',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? AdminEmptyState(
                  icon: Icons.badge_outlined,
                  title: _query.isEmpty
                      ? 'No faculty yet'
                      : 'No faculty found',
                  subtitle: _query.isEmpty
                      ? 'Tap "Add faculty" to create a faculty login.'
                      : 'Try a different name or email.',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return AdminListHeader(
                          '${list.length} faculty member${list.length == 1 ? '' : 's'}');
                    }
                    final f = list[i - 1];
                    return AdminCard(
                      onTap: () => _showCredentials(f),
                      child: Row(
                        children: [
                          AdminAvatar(
                            text: f.name,
                            colors: const [
                              Color(0xFF10B981),
                              Color(0xFF047857)
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(f.name,
                                    style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: AdminUi.ink)),
                                const SizedBox(height: 3),
                                Text(f.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AdminUi.muted)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            onSelected: (v) {
                              if (v == 'edit') _showForm(faculty: f);
                              if (v == 'login') _showCredentials(f);
                              if (v == 'share') _shareLogin(f);
                              if (v == 'delete') _delete(f);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      size: 19, color: AdminUi.blue),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'login',
                                child: Row(children: [
                                  Icon(Icons.vpn_key_outlined,
                                      size: 19,
                                      color: Color(0xFFD97706)),
                                  SizedBox(width: 10),
                                  Text('Login details'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'share',
                                child: Row(children: [
                                  Icon(Icons.share_outlined,
                                      size: 19,
                                      color: Color(0xFF059669)),
                                  SizedBox(width: 10),
                                  Text('Share login'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 19,
                                      color: AdminUi.danger),
                                  SizedBox(width: 10),
                                  Text('Delete'),
                                ]),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.more_vert_rounded,
                                  color: AdminUi.muted),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyDialog extends StatefulWidget {
  final Faculty? faculty;

  /// Return an error message to keep the dialog open, or null on success.
  final String? Function(String name, String email, String password) onSave;

  const _FacultyDialog({this.faculty, required this.onSave});

  @override
  State<_FacultyDialog> createState() => _FacultyDialogState();
}

class _FacultyDialogState extends State<_FacultyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _obscure = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.faculty?.name ?? '');
    _email = TextEditingController(text: widget.faculty?.email ?? '');
    _password = TextEditingController(
      text: widget.faculty?.password.isNotEmpty == true
          ? widget.faculty!.password
          : generatePassword(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) =>
      adminInputDecoration(label, icon, suffix: suffix);

  @override
  Widget build(BuildContext context) {
    final editing = widget.faculty != null;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminDialogHeader(
                  icon: editing
                      ? Icons.edit_outlined
                      : Icons.person_add_alt_1_rounded,
                  title: editing ? 'Edit faculty' : 'Add faculty',
                  subtitle: editing
                      ? 'Update the details and login'
                      : 'Create a faculty login',
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Name', Icons.person),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Email', Icons.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: _dec(
                    'Login Password',
                    Icons.lock,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Show / hide',
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        IconButton(
                          tooltip: 'Generate password',
                          icon: const Icon(Icons.autorenew),
                          onPressed: () => setState(
                                  () => _password.text = generatePassword()),
                        ),
                      ],
                    ),
                  ),
                  validator: (v) => v == null || v.trim().length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final error = widget.onSave(
                          _name.text.trim(),
                          _email.text.trim(),
                          _password.text.trim(),
                        );
                        if (error != null) {
                          setState(() => _error = error);
                          return;
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(editing
                              ? 'Faculty updated'
                              : 'Faculty added'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminUi.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(editing ? 'Update' : 'Add faculty'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}