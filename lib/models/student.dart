class Student {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  /// Class division, e.g. A, B, 10-A (empty = unassigned).
  final String division;
  /// Login password set by the admin/faculty and given to the student.
  final String password;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    this.division = '',
    this.password = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Student copyWith({
    String? name,
    String? email,
    String? rollNumber,
    String? password,
    String? division,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNumber: rollNumber ?? this.rollNumber,
      password: password ?? this.password,
      division: division ?? this.division,
      createdAt: createdAt,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      rollNumber: map['rollNumber'] as String,
      password: map['password'] as String? ?? '',
      division: map['division'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'rollNumber': rollNumber,
    'password': password,
    'division': division,
    'createdAt': createdAt.toIso8601String(),
  };
}