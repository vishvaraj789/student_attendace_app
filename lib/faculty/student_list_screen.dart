import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student.dart';
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
          title: Text('${student.name}\'s login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Email', student.email),
              if (hasPassword)
                row('Password', student.password)
              else
                Text(
                  'No password set yet. Edit this student to set one.',
                  style: TextStyle(color: Colors.red[400]),
                ),
              const SizedBox(height: 8),
              Text(
                'Give these to the student. They log in with the Student option.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            if (hasPassword)
              TextButton(
                onPressed: () => copy('Login details',
                    'Email: ${student.email}\nPassword: ${student.password}'),
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

  void _deleteStudent(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Student'),
        content: const Text(
            'Are you sure you want to delete this student? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                students.removeWhere((s) => s.id == id);
              });
              StudentRepository.saveAll(students);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          final n = counts[item] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item == 'Unassigned'
                        ? Colors.grey
                        : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item == 'Unassigned' ? 'Unassigned' : 'Division $item',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '$n student${n == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        final student = item as Student;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StudentCard(
            student: student,
            onEdit: () => _showEditStudentDialog(student),
            onCredentials: () => _showCredentials(student),
            onDelete: () => _deleteStudent(student.id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Students',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, roll number, or email',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    setState(() => searchQuery = '');
                  },
                  child: Icon(Icons.close, color: Colors.grey[600]),
                )
                    : null,
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
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Division filter
          if (students.isNotEmpty)
            SizedBox(
              height: 44,
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
                        selectedColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.18),
                        onSelected: (_) =>
                            setState(() => _divisionFilter = option),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Student List
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isEmpty
                        ? 'No students yet'
                        : 'No students found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isEmpty
                        ? 'Add a new student to get started'
                        : 'Try a different search term',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : _buildGroupedList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StudentCard extends StatefulWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onCredentials;
  final VoidCallback onDelete;

  const StudentCard({
    required this.student,
    required this.onEdit,
    required this.onCredentials,
    required this.onDelete,
    super.key,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.1 : 0.06),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.student.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Roll: ${widget.student.rollNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        if (widget.student.division.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Div ${widget.student.division}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.student.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit();
                  } else if (value == 'credentials') {
                    widget.onCredentials();
                  } else if (value == 'delete') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'credentials',
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Login details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student == null ? 'Add Student' : 'Edit Student',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter student name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Roll Number Field
                TextFormField(
                  controller: rollNumberController,
                  decoration: InputDecoration(
                    labelText: 'Roll Number',
                    hintText: 'Enter roll number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Roll number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Division Field
                TextFormField(
                  controller: divisionController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Division',
                    hintText: 'e.g. A, B, 10-A',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.groups),
                  ),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final d in widget.existingDivisions)
                        ActionChip(
                          label: Text('Div $d'),
                          onPressed: () =>
                              setState(() => divisionController.text = d),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
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
                const SizedBox(height: 16),
                // Password Field (given to the student for login)
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Login Password',
                    hintText: 'At least 6 characters',
                    helperText: 'Give this email and password to the student',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Show / hide',
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                        IconButton(
                          tooltip: 'Generate password',
                          icon: const Icon(Icons.autorenew),
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
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                // Action Buttons
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
                              content: Text(widget.student == null
                                  ? 'Student added successfully'
                                  : 'Student updated successfully'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        widget.student == null ? 'Add' : 'Update',
                        style: const TextStyle(color: Colors.white),
                      ),
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