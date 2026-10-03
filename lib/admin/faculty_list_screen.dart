import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../faculty/student_list_screen.dart' show generatePassword;
import '../models/faculty.dart';
import '../utils/admin_auth.dart';
import '../utils/faculty_repository.dart';

/// Admin screen: add, view, edit and delete faculty accounts.
class FacultyListScreen extends StatefulWidget {
  const FacultyListScreen({super.key});

  @override
  State<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen> {
  static const _accent = Color(0xFF6366F1);

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

        Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    SelectableText(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => copy(label, value),
              ),
            ],
          ),
        );

        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('${f.name}\'s login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Email', f.email),
              row('Password', f.password),
              const SizedBox(height: 8),
              Text(
                'Give these to the faculty. They log in with the Faculty option.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => copy('Login details',
                  'Email: ${f.email}\nPassword: ${f.password}'),
              child: const Text('Copy both'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _delete(Faculty f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Faculty'),
        content: Text(
            'Delete ${f.name}? They will no longer be able to log in. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _faculty.removeWhere((x) => x.id == f.id));
              FacultyRepository.saveAll(_faculty);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Faculty',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty
                        ? 'No faculty yet'
                        : 'No faculty found',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                  if (_query.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Tap + to create a faculty login',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            f.name.isEmpty
                                ? '?'
                                : f.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(f.email,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showForm(faculty: f);
                          if (v == 'login') _showCredentials(f);
                          if (v == 'delete') _delete(f);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'login',
                            child: Row(children: [
                              Icon(Icons.vpn_key,
                                  size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Login details'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ]),
                          ),
                        ],
                        child:
                        Icon(Icons.more_vert, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: _accent,
        child: const Icon(Icons.add),
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
  static const _accent = Color(0xFF6366F1);

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
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.faculty != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'Edit Faculty' : 'Add Faculty',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
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
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(editing ? 'Update' : 'Add',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}