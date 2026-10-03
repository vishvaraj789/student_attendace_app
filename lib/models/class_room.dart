import 'package:flutter/material.dart';

class ClassRoom {
  final String id;
  final String name;
  final String subject;
  final String section;
  /// Division this class belongs to. Empty = all divisions (older classes).
  final String division;
  final List<String> days;
  final TimeOfDay startTime;
  final DateTime createdAt;

  ClassRoom({
    required this.id,
    required this.name,
    required this.subject,
    required this.section,
    this.division = '',
    required this.days,
    required this.startTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get divisionLabel => division.isEmpty ? 'All divisions' : 'Div $division';

  /// True if a student with this division belongs in this class.
  bool includesDivision(String studentDivision) =>
      division.isEmpty ||
          division.toLowerCase() == studentDivision.toLowerCase();

  factory ClassRoom.fromMap(Map<String, dynamic> map) {
    return ClassRoom(
      id: map['id'] as String,
      name: map['name'] as String,
      subject: map['subject'] as String? ?? '',
      section: map['section'] as String? ?? '',
      division: map['division'] as String? ?? '',
      days: List<String>.from(map['days'] as List<dynamic>? ?? const []),
      startTime: TimeOfDay(
        hour: map['hour'] as int? ?? 9,
        minute: map['minute'] as int? ?? 0,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'subject': subject,
    'section': section,
    'division': division,
    'days': days,
    'hour': startTime.hour,
    'minute': startTime.minute,
    'createdAt': createdAt.toIso8601String(),
  };
}