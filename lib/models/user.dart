class User {
  final int? userId;
  final String username;
  final String passwordHash;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int syncStatus;

  User({
    this.userId,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
    this.syncStatus = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      fullName: map['full_name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login']) 
          : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role.toString().split('.').last,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? passwordHash,
    String? fullName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? syncStatus,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'User{userId: $userId, username: $username, fullName: $fullName, role: $role}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username;

  @override
  int get hashCode => userId.hashCode ^ username.hashCode;
}

enum UserRole {
  owner,
  employee,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Nyir\'ibar'; // Owner
      case UserRole.employee:
        return 'Umukozi'; // Employee
    }
  }

  bool get canManageProducts => this == UserRole.owner;
  bool get canManageUsers => this == UserRole.owner;
  bool get canViewDetailedReports => this == UserRole.owner;
  bool get canExportReports => this == UserRole.owner;
}
