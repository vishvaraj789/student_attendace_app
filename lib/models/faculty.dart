class Faculty {
  final String id;
  final String name;
  final String email;
  final String password;

  const Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Faculty copyWith({String? name, String? email, String? password}) {
    return Faculty(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  factory Faculty.fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
  };
}