import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../config/app_config.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();
  static const String _currentUserKey = 'current_user';
  static const String _sessionTokenKey = 'session_token';
  static const String _lastLoginKey = 'last_login';
  static const String _rememberMeKey = 'remember_me';

  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;

  // Get current user
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialize authentication service
  Future<void> initialize() async {
    await _loadCurrentUser();
    await _checkSessionExpiry();
  }

  // Login with username and password
  Future<AuthResult> login(String username, String password, {bool rememberMe = false}) async {
    try {
      // Validate input
      if (username.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Uzuza izina n\'ijambo ryibanga');
      }

      // Get user from database
      final user = await _databaseService.getUserByUsername(username.trim());
      if (user == null) {
        return AuthResult.failure('Izina cyangwa ijambo ryibanga ntibikwiye');
      }

      // Verify password
      if (!_verifyPassword(password, user.passwordHash)) {
        return AuthResult.failure('Izina cyangwa ijambo ryibanga ntibikwiye');
      }

      // Check if user is active
      if (!user.isActive) {
        return AuthResult.failure('Konti yawe ntikiri ikora');
      }

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _databaseService.updateUser(updatedUser);

      // Set current user
      _currentUser = updatedUser;

      // Save session
      await _saveSession(updatedUser, rememberMe);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
  }

  // Change password
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('Ntujyewe muri sisitemu');
      }

      // Verify current password
      if (!_verifyPassword(currentPassword, _currentUser!.passwordHash)) {
        return AuthResult.failure('Ijambo ryibanga rya none ntikwiye');
      }

      // Validate new password
      if (newPassword.length < 4) {
        return AuthResult.failure('Ijambo ryibanga rishya rigomba kuba rifite ibyangombwa 4 byibuze');
      }

      // Hash new password
      final newPasswordHash = _hashPassword(newPassword);

      // Update user
      final updatedUser = _currentUser!.copyWith(passwordHash: newPasswordHash);
      await _databaseService.updateUser(updatedUser);

      _currentUser = updatedUser;

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Create new user (owner only)
  Future<AuthResult> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      // Check if current user is owner
      if (_currentUser?.role != UserRole.owner) {
        return AuthResult.failure('Ntufite uburenganzira bwo gukora konti');
      }

      // Validate input
      if (username.trim().isEmpty || password.isEmpty || fullName.trim().isEmpty) {
        return AuthResult.failure('Uzuza amakuru yose');
      }

      // Check if username already exists
      final existingUser = await _databaseService.getUserByUsername(username.trim());
      if (existingUser != null) {
        return AuthResult.failure('Iri zina rihari');
      }

      // Create new user
      final newUser = User(
        username: username.trim(),
        passwordHash: _hashPassword(password),
        fullName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      final userId = await _databaseService.insertUser(newUser);
      final createdUser = newUser.copyWith(userId: userId);

      return AuthResult.success(createdUser);
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Update user (owner only)
  Future<AuthResult> updateUser(User user) async {
    try {
      // Check if current user is owner or updating themselves
      if (_currentUser?.role != UserRole.owner && _currentUser?.userId != user.userId) {
        return AuthResult.failure('Ntufite uburenganzira bwo guhindura uyu mukoresha');
      }

      await _databaseService.updateUser(user);

      // Update current user if it's the same user
      if (_currentUser?.userId == user.userId) {
        _currentUser = user;
        await _saveCurrentUser(user);
      }

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Get all users (owner only)
  Future<List<User>> getAllUsers() async {
    if (_currentUser?.role != UserRole.owner) {
      return [];
    }
    return await _databaseService.getAllUsers();
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // Save session
  Future<void> _saveSession(User user, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Generate session token
    final sessionToken = _generateSessionToken();
    
    // Save to secure storage
    await _storage.write(key: _sessionTokenKey, value: sessionToken);
    await _saveCurrentUser(user);
    
    // Save preferences
    await prefs.setBool(_rememberMeKey, rememberMe);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  // Save current user
  Future<void> _saveCurrentUser(User user) async {
    await _storage.write(key: _currentUserKey, value: jsonEncode(user.toMap()));
  }

  // Load current user
  Future<void> _loadCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _currentUserKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        _currentUser = User.fromMap(userMap);
      }
    } catch (e) {
      // Clear invalid session
      await _clearSession();
    }
  }

  // Clear session
  Future<void> _clearSession() async {
    await _storage.delete(key: _currentUserKey);
    await _storage.delete(key: _sessionTokenKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
  }

  // Check session expiry
  Future<void> _checkSessionExpiry() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString(_lastLoginKey);
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final now = DateTime.now();
        final sessionDuration = now.difference(lastLogin);

        // Check if session expired (8 hours for regular, 30 days for remember me)
        final maxDuration = rememberMe 
            ? const Duration(days: 30)
            : Duration(hours: AppConfig.sessionTimeoutHours);

        if (sessionDuration > maxDuration) {
          await logout();
        }
      }
    } catch (e) {
      // Clear invalid session
      await logout();
    }
  }

  // Generate session token
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$timestamp$random';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if user has permission
  bool hasPermission(Permission permission) {
    if (_currentUser == null) return false;

    switch (permission) {
      case Permission.manageProducts:
        return _currentUser!.role.canManageProducts;
      case Permission.manageUsers:
        return _currentUser!.role.canManageUsers;
      case Permission.viewDetailedReports:
        return _currentUser!.role.canViewDetailedReports;
      case Permission.exportReports:
        return _currentUser!.role.canExportReports;
      case Permission.recordStock:
        return true; // All users can record stock
      case Permission.viewDashboard:
        return true; // All users can view dashboard
    }
  }

  // Auto-login check
  Future<bool> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (rememberMe && _currentUser != null) {
        await _checkSessionExpiry();
        return _currentUser != null;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Authentication result class
class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult._(this.success, this.message, this.user);

  factory AuthResult.success(User user) {
    return AuthResult._(true, null, user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(false, message, null);
  }
}

// Permissions enum
enum Permission {
  manageProducts,
  manageUsers,
  viewDetailedReports,
  exportReports,
  recordStock,
  viewDashboard,
}
