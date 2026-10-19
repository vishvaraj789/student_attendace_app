import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/app_user.dart';
import '../models/faculty.dart';
import '../utils/faculty_repository.dart';
import '../utils/shared_preference.dart';
import '../models/class_room.dart';
import '../utils/student_repository.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _accent = AdminUi.blue;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  late final List<String> _divisions;
  String? _division; // '' = all divisions
  bool _divisionError = false;

  // Admin can assign the new class to a faculty member.
  late final bool _isAdmin;
  List<Faculty> _facultyList = [];
  String _facultyId = '';

  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  bool _daysError = false;

  @override
  void initState() {
    super.initState();
    _divisions = StudentRepository.getAll()
        .map((s) => s.division)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _isAdmin = SharedPrefsUtil.getString('user_role') == UserRole.admin.asString;
    if (_isAdmin) _facultyList = FacultyRepository.getAll();
    // Only one division exists: select it for convenience.
    if (_divisions.length == 1) _division = _divisions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  void _save() {
    final formOk = _formKey.currentState!.validate();
    final daysOk = _selectedDays.isNotEmpty;
    setState(() => _daysError = !daysOk);

    if (!formOk || !daysOk || _startTime == null) {
      if (_startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a start time')),
        );
      }
      return;
    }

    if (_division == null) {
      setState(() => _divisionError = true);
      return;
    }

    final subject = _subjectController.text.trim();
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      name = _division!.isEmpty ? subject : '$subject - Div $_division';
    }

    final classRoom = ClassRoom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      subject: subject,
      section: '',
      division: _division!,
      // keep Mon..Sat order regardless of tap order
      days: _allDays.where(_selectedDays.contains).toList(),
      startTime: _startTime!,
      // Admin picks a faculty; a faculty creating a class owns it.
      facultyId:
      _isAdmin ? _facultyId : SharedPrefsUtil.getString('user_id'),
    );

    // Hand the new class back to whoever opened this screen.
    Navigator.pop(context, classRoom);
  }

  InputDecoration _decoration(String label, String hint, IconData icon) =>
      adminInputDecoration(label, icon).copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      );

  Widget _section(String title, {String? hint, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminUi.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.ink)),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint,
                style: const TextStyle(fontSize: 12.5, color: AdminUi.muted)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  ChipThemeData _chipTheme(BuildContext context) =>
      ChipTheme.of(context).copyWith(
        backgroundColor: const Color(0xFFF3F4F6),
        side: const BorderSide(color: AdminUi.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 13.5, color: AdminUi.ink),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: adminAppBar('Create Class'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(chipTheme: _chipTheme(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section(
                        'Class details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                  'Class name (optional)',
                                  'Auto: subject + division',
                                  Icons.class_outlined),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _subjectController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                  'Subject',
                                  'e.g. Mobile App Development',
                                  Icons.menu_book_outlined),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Subject is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      _section(
                        'Division',
                        hint: 'Attendance will list only this division\'s students',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _divisions)
                                  ChoiceChip(
                                    label: Text('Div $d'),
                                    selected: _division == d,
                                    selectedColor:
                                    _accent.withValues(alpha: 0.15),
                                    onSelected: (_) => setState(() {
                                      _division = d;
                                      _divisionError = false;
                                    }),
                                  ),
                                ChoiceChip(
                                  label: const Text('All divisions'),
                                  selected: _division == '',
                                  selectedColor:
                                  _accent.withValues(alpha: 0.15),
                                  onSelected: (_) => setState(() {
                                    _division = '';
                                    _divisionError = false;
                                  }),
                                ),
                              ],
                            ),
                            if (_divisions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'No divisions yet. Add students with a division first, or choose All divisions.',
                                  style: TextStyle(
                                      fontSize: 12, color: AdminUi.muted),
                                ),
                              ),
                            if (_divisionError)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Please choose a division',
                                  style: TextStyle(
                                      color: AdminUi.danger, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isAdmin)
                        _section(
                          'Assign to faculty',
                          hint:
                          'Optional. The faculty sees this class on their home screen and can take attendance in one tap.',
                          child: _facultyList.isEmpty
                              ? const Text(
                            'No faculty yet. Add faculty first, or assign later from the Classes list.',
                            style: TextStyle(
                                fontSize: 12.5, color: AdminUi.muted),
                          )
                              : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Not assigned'),
                                selected: _facultyId.isEmpty,
                                selectedColor:
                                _accent.withValues(alpha: 0.15),
                                onSelected: (_) =>
                                    setState(() => _facultyId = ''),
                              ),
                              for (final f in _facultyList)
                                ChoiceChip(
                                  label: Text(f.name),
                                  selected: _facultyId == f.id,
                                  selectedColor:
                                  _accent.withValues(alpha: 0.15),
                                  onSelected: (_) =>
                                      setState(() => _facultyId = f.id),
                                ),
                            ],
                          ),
                        ),
                      _section(
                        'Schedule',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Class days',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AdminUi.muted)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allDays.map((day) {
                                final selected = _selectedDays.contains(day);
                                return FilterChip(
                                  label: Text(day),
                                  selected: selected,
                                  selectedColor:
                                  _accent.withValues(alpha: 0.15),
                                  checkmarkColor: _accent,
                                  onSelected: (value) {
                                    setState(() {
                                      value
                                          ? _selectedDays.add(day)
                                          : _selectedDays.remove(day);
                                      _daysError = false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (_daysError)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Select at least one day',
                                  style: TextStyle(
                                      color: AdminUi.danger, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time_rounded),
                              label: Text(
                                _startTime == null
                                    ? 'Pick start time'
                                    : 'Starts at ${_startTime!.format(context)}',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AdminUi.ink,
                                side: const BorderSide(color: AdminUi.line),
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'Create class',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}