import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin/admin_ui.dart';
import '../models/student.dart';
import '../utils/login_share.dart';
import '../utils/student_repository.dart';

/// Random 8-character password (no look-alike characters like 0/O, 1/l).
String generatePassword([int length = 8]) {
  const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rnd = Random.secure();
  return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late List<Student> students = [];
  String searchQuery = '';
  String _divisionFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    students = StudentRepository.getAll();
  }

  /// Returns an error message if the roll number/email is already used
  /// by another student, otherwise null.
  String? _findDuplicate(String rollNumber, String email, {String? excludeId}) {
    for (final s in students) {
      if (s.id == excludeId) continue;
      if (s.rollNumber.toLowerCase() == rollNumber.toLowerCase()) {
        return 'A student with this roll number already exists';
      }
      if (s.email.toLowerCase() == email.toLowerCase()) {
        return 'A student with this email already exists';
      }
    }
    return null;
  }

  String _divOf(Student s) => s.division.isEmpty ? 'Unassigned' : s.division;

  /// Division names in use (sorted), without 'Unassigned'.
  List<String> get _divisions {
    final set = students
        .map((s) => s.division)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  /// Filter options: All, each division, and Unassigned if any.
  List<String> get _filterOptions => [
    'All',
    ..._divisions,
    if (students.any((s) => s.division.isEmpty)) 'Unassigned',
  ];

  String get _activeFilter =>
      _filterOptions.contains(_divisionFilter) ? _divisionFilter : 'All';

  int _countFor(String option) => option == 'All'
      ? students.length
      : students.where((s) => _divOf(s) == option).length;

  List<Student> get filteredStudents {
    final q = searchQuery.toLowerCase();
    final list = students.where((student) {
      if (_activeFilter != 'All' && _divOf(student) != _activeFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return student.name.toLowerCase().contains(q) ||
          student.rollNumber.toLowerCase().contains(q) ||
          student.email.toLowerCase().contains(q) ||
          student.division.toLowerCase().contains(q);
    }).toList();
    // Group by division (Unassigned last), then by name.
    String key(Student s) =>
        s.division.isEmpty ? '\uffff' : s.division.toLowerCase();
    list.sort((a, b) {
      final c = key(a).compareTo(key(b));
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditStudentDialog(
        existingDivisions: _divisions,
        initialDivision:
        (_activeFilter == 'All' || _activeFilter == 'Unassigned')
            ? ''
            : _activeFilter,
        onSave: (name, email, rollNumber, password, division) {
          final error = _findDuplicate(rollNumber, email);
          if (error != null) return error;
          setState(() {
            students.add(
              Student(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                email: email,
                rollNumber: rollNumber,
                password: password,
                division: division,
              ),
            );
          });
          StudentRepository.saveAll(students);
          return null;
        },
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => AddEditStudentDialog(
        student: student,
        existingDivisions: _divisions,
        onSave: (name, email, rollNumber, password, division) {
          final error =
          _findDuplicate(rollNumber, email, excludeId: student.id);
          if (error != null) return error;
          setState(() {
            final index = students.indexWhere((s) => s.id == student.id);
            if (index != -1) {
              students[index] = student.copyWith(
                name: name,
                email: email,
                rollNumber: rollNumber,
                password: password,
                division: division,
              );
            }
          });
          StudentRepository.saveAll(students);
          return null;
        },
      ),
    );
  }

  void _shareLogin(Student student) {
    LoginShare.share(
      context,
      name: student.name,
      role: 'Student',
      email: student.email,
      password: student.password,
    );
  }

  void _showCredentials(Student student) {
    showDialog(
      context: context,
      builder: (ctx) {
        final hasPassword = student.password.isNotEmpty;

        void copy(String label, String text) {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('$label copied'),
              duration: const Duration(seconds: 1),
            ),
          );
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
            subtitle: student.name,
            color: const Color(0xFFD97706),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Email', student.email, Icons.mail_outline_rounded),
              if (hasPassword)
                row('Password', student.password, Icons.lock_outline_rounded)
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No password set yet. Edit this student to set one.',
                    style: TextStyle(color: AdminUi.danger, fontSize: 13),
                  ),
                ),
              const Text(
                'Give these to the student. They sign in on the login page.',
                style: TextStyle(fontSize: 12.5, color: AdminUi.muted),
              ),
            ],
          ),
          actions: [
            if (hasPassword)
              TextButton(
                onPressed: () => copy('Login details',
                    'Email: ${student.email}\nPassword: ${student.password}'),
                child: const Text('Copy'),
              ),
            TextButton.icon(
              onPressed: () => _shareLogin(student),
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

  Future<void> _deleteStudent(String id) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Delete student?',
      message: 'Are you sure you want to delete this student? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    setState(() {
      students.removeWhere((s) => s.id == id);
    });
    StudentRepository.saveAll(students);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student deleted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Students listed under a header per division (when "All" is selected).
  Widget _buildGroupedList() {
    final list = filteredStudents;
    final grouped = _activeFilter == 'All';
    final counts = <String, int>{};
    for (final s in list) {
      counts[_divOf(s)] = (counts[_divOf(s)] ?? 0) + 1;
    }

    final items = <Object>[];
    String? last;
    for (final s in list) {
      final d = _divOf(s);
      if (grouped && d != last) {
        items.add(d);
        last = d;
      }
      items.add(s);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          final n = counts[item] ?? 0;
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: item == 'Unassigned'
                        ? AdminUi.muted
                        : AdminUi.navy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item == 'Unassigned' ? 'Unassigned' : 'Division $item',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$n student${n == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12.5, color: AdminUi.muted),
                ),
              ],
            ),
          );
        }
        final student = item as Student;
        return StudentCard(
          student: student,
          onEdit: () => _showEditStudentDialog(student),
          onCredentials: () => _showCredentials(student),
          onShare: () => _shareLogin(student),
          onDelete: () => _deleteStudent(student.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredStudents;
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Students'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: AdminUi.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add student'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: AdminSearchField(
                  hint: 'Search by name, roll number or email',
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              if (students.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final option in _filterOptions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              option == 'All'
                                  ? 'All (${_countFor(option)})'
                                  : option == 'Unassigned'
                                  ? 'Unassigned (${_countFor(option)})'
                                  : 'Div $option (${_countFor(option)})',
                            ),
                            selected: _activeFilter == option,
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: AdminUi.blue,
                            side: BorderSide(
                              color: _activeFilter == option
                                  ? AdminUi.blue
                                  : AdminUi.line,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _activeFilter == option
                                  ? Colors.white
                                  : AdminUi.ink,
                            ),
                            onSelected: (_) =>
                                setState(() => _divisionFilter = option),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: list.isEmpty
                    ? AdminEmptyState(
                  icon: Icons.school_outlined,
                  title: searchQuery.isEmpty
                      ? 'No students yet'
                      : 'No students found',
                  subtitle: searchQuery.isEmpty
                      ? 'Tap "Add student" to get started.'
                      : 'Try a different search term.',
                )
                    : _buildGroupedList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onCredentials;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const StudentCard({
    required this.student,
    required this.onEdit,
    required this.onCredentials,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
  );

  PopupMenuItem<String> _item(
      String value, IconData icon, Color color, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Text(label),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onCredentials,
      child: Row(
        children: [
          AdminAvatar(
            text: student.name,
            colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AdminUi.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _tag('Roll: ${student.rollNumber}', AdminUi.blue),
                    if (student.division.isNotEmpty)
                      _tag('Div ${student.division}', const Color(0xFF059669)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  student.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AdminUi.muted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'credentials') onCredentials();
              if (value == 'share') onShare();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              _item('edit', Icons.edit_outlined, AdminUi.blue, 'Edit'),
              _item('credentials', Icons.vpn_key_outlined,
                  const Color(0xFFD97706), 'Login details'),
              _item('share', Icons.share_outlined, const Color(0xFF059669),
                  'Share login'),
              _item('delete', Icons.delete_outline_rounded, AdminUi.danger,
                  'Delete'),
            ],
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.more_vert_rounded, color: AdminUi.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class AddEditStudentDialog extends StatefulWidget {
  final Student? student;
  /// Return an error message to keep the dialog open, or null on success.
  final String? Function(String name, String email, String rollNumber,
      String password, String division) onSave;

  /// Divisions already in use, shown as quick-pick chips.
  final List<String> existingDivisions;

  /// Pre-filled division for a new student (e.g. the active filter).
  final String initialDivision;

  const AddEditStudentDialog({
    this.student,
    this.existingDivisions = const [],
    this.initialDivision = '',
    required this.onSave,
    super.key,
  });

  @override
  State<AddEditStudentDialog> createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController rollNumberController;
  late TextEditingController passwordController;
  late TextEditingController divisionController;
  bool _obscurePassword = false;
  final formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student?.name ?? '');
    emailController =
        TextEditingController(text: widget.student?.email ?? '');
    rollNumberController =
        TextEditingController(text: widget.student?.rollNumber ?? '');
    divisionController = TextEditingController(
        text: widget.student?.division ?? widget.initialDivision);
    // New student: suggest a random password the admin can change.
    passwordController = TextEditingController(
      text: widget.student?.password.isNotEmpty == true
          ? widget.student!.password
          : generatePassword(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    rollNumberController.dispose();
    passwordController.dispose();
    divisionController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, String hint, IconData icon,
      {Widget? suffix, String? helper}) =>
      adminInputDecoration(label, icon, suffix: suffix).copyWith(
        hintText: hint,
        helperText: helper,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminDialogHeader(
                    icon: editing
                        ? Icons.edit_outlined
                        : Icons.person_add_alt_1_rounded,
                    title: editing ? 'Edit student' : 'Add student',
                    subtitle: editing
                        ? 'Update the details and login'
                        : 'Create a student login',
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('Name', 'Enter student name',
                        Icons.person_outline_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: rollNumberController,
                    decoration: _dec('Roll number', 'Enter roll number',
                        Icons.badge_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Roll number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: divisionController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dec('Division', 'e.g. A, B, 10-A',
                        Icons.groups_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Division is required';
                      }
                      if (value.trim().length > 10) {
                        return 'Keep the division short (max 10 characters)';
                      }
                      return null;
                    },
                  ),
                  if (widget.existingDivisions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final d in widget.existingDivisions)
                          ActionChip(
                            label: Text('Div $d'),
                            backgroundColor: const Color(0xFFF3F4F6),
                            side: const BorderSide(color: AdminUi.line),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            onPressed: () =>
                                setState(() => divisionController.text = d),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Email', 'Enter email address',
                        Icons.mail_outline_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: _dec(
                      'Login password',
                      'At least 6 characters',
                      Icons.lock_outline_rounded,
                      helper: 'Give this email and password to the student',
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Show / hide',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          ),
                          IconButton(
                            tooltip: 'Generate password',
                            icon: const Icon(Icons.autorenew_rounded,
                                size: 20),
                            onPressed: () => setState(() {
                              passwordController.text = generatePassword();
                            }),
                          ),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: AdminUi.danger, fontSize: 13)),
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
                          if (formKey.currentState!.validate()) {
                            final error = widget.onSave(
                              nameController.text.trim(),
                              emailController.text.trim(),
                              rollNumberController.text.trim(),
                              passwordController.text.trim(),
                              divisionController.text.trim().toUpperCase(),
                            );
                            if (error != null) {
                              setState(() => _error = error);
                              return;
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(editing
                                    ? 'Student updated successfully'
                                    : 'Student added successfully'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminUi.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(editing ? 'Update' : 'Add student'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}