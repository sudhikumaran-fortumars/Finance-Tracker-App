import 'user_role.dart';

class AppUser {
  final String id;
  final String username;
  final String email;
  final String password; // In production, this should be hashed
  final UserRole role;
  final String? fullName;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.fullName,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    UserRole? role,
    String? fullName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'role': role.name,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.staff,
      ),
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, username: $username, role: ${role.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

