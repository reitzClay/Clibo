class User {
  final int? id;
  final String email;
  final String name;
  final String userTier;
  final String systemRole;
  final String? token;

  const User({
    this.id,
    required this.email,
    required this.name,
    this.userTier = 'FREE',
    this.systemRole = 'USER',
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['email']?.toString().split('@').first ?? 'User',
      userTier: json['userTier']?.toString() ?? 'FREE',
      systemRole: json['systemRole']?.toString() ?? 'USER',
      token: token ?? json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      'userTier': userTier,
      'systemRole': systemRole,
      if (token != null) 'token': token,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? userTier,
    String? systemRole,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userTier: userTier ?? this.userTier,
      systemRole: systemRole ?? this.systemRole,
      token: token ?? this.token,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, userTier: $userTier, systemRole: $systemRole)';
  }
}
