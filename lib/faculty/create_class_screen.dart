import 'package:flutter/material.dart';
import '../models/class_room.dart';
import '../utils/student_repository.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _accent = Color(0xFF10B981);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  late final List<String> _divisions;
  String? _division; // '' = all divisions
  bool _divisionError = false;

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

    final classRoom = ClassRoom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      subject: _subjectController.text.trim(),
      section: '',
      division: _division!,
      // keep Mon..Sat order regardless of tap order
      days: _allDays.where(_selectedDays.contains).toList(),
      startTime: _startTime!,
    );

    // Hand the new class back to whoever opened this screen.
    Navigator.pop(context, classRoom);
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Create Class',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                          'Class Name', 'e.g. BCA Sem 5', Icons.class_rounded),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Class name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                          'Subject', 'e.g. Mobile App Development', Icons.book),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Subject is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Division',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance will list only this division\'s students',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final d in _divisions)
                          ChoiceChip(
                            label: Text('Div $d'),
                            selected: _division == d,
                            selectedColor: _accent.withValues(alpha: 0.2),
                            onSelected: (_) => setState(() {
                              _division = d;
                              _divisionError = false;
                            }),
                          ),
                        ChoiceChip(
                          label: const Text('All divisions'),
                          selected: _division == '',
                          selectedColor: _accent.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() {
                            _division = '';
                            _divisionError = false;
                          }),
                        ),
                      ],
                    ),
                    if (_divisions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'No divisions yet. Add students with a division first, or choose All divisions.',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    if (_divisionError)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Please choose a division',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Class days',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDays.map((day) {
                        final selected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: selected,
                          selectedColor: _accent.withValues(alpha: 0.2),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Select at least one day',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _startTime == null
                            ? 'Pick start time'
                            : 'Starts at ${_startTime!.format(context)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Class',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}