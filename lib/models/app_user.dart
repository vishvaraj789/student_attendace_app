enum UserRole { faculty, student, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.admin:
        return 'Admin';
      case UserRole.student:
        return 'Student';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'faculty':
        return UserRole.faculty;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  String get asString {
    switch (this) {
      case UserRole.faculty:
        return 'faculty';
      case UserRole.admin:
        return 'admin';
      case UserRole.student:
        return 'student';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRoleX.fromString(map['role'] as String? ?? 'student'),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.asString,
  };
}