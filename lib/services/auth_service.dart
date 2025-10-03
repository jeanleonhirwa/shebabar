import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:convert';
import '../models/user.dart' as app_user;
import '../config/app_config.dart';
import 'firebase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();
  static const String _currentUserKey = 'current_user';
  static const String _sessionTokenKey = 'session_token';
  static const String _lastLoginKey = 'last_login';
  static const String _rememberMeKey = 'remember_me';

  final FirebaseService _firebaseService = FirebaseService();
  app_user.User? _currentUser;

  // Get current user
  app_user.User? get currentUser => _currentUser;
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

      // Get user from Firebase
      final user = await _firebaseService.getUserByUsername(username.trim());
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
      await _firebaseService.updateUserProfile(updatedUser);

      // Set current user
      _currentUser = updatedUser;

      // Save session
      await _saveSession(updatedUser, rememberMe);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Login with Firebase Auth (email/password)
  Future<AuthResult> loginWithFirebaseAuth(String email, String password, {bool rememberMe = false}) async {
    try {
      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Uzuza email n\'ijambo ryibanga');
      }

      // Sign in with Firebase Auth
      final credential = await _firebaseService.signInWithEmailAndPassword(email, password);
      if (credential?.user == null) {
        return AuthResult.failure('Ntibyashobotse kwinjira');
      }

      // Get user profile from Firestore
      final userProfile = await _firebaseService.getUserProfile(credential!.user!.uid);
      if (userProfile == null) {
        return AuthResult.failure('Profil y\'ukoresha ntiboneka');
      }

      // Check if user is active
      if (!userProfile.isActive) {
        return AuthResult.failure('Konti yawe ntikiri ikora');
      }

      // Update last login
      final updatedUser = userProfile.copyWith(lastLogin: DateTime.now());
      await _firebaseService.updateUserProfile(updatedUser);

      // Set current user
      _currentUser = updatedUser;

      // Save session
      await _saveSession(updatedUser, rememberMe);

      return AuthResult.success(updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.failure('Nta mukoresha uboneka');
        case 'wrong-password':
          return AuthResult.failure('Ijambo ryibanga ntikwiye');
        case 'invalid-email':
          return AuthResult.failure('Email ntikwiye');
        case 'user-disabled':
          return AuthResult.failure('Konti yahagaritswe');
        default:
          return AuthResult.failure('Habayeho ikosa: ${e.message}');
      }
    } catch (e) {
      return AuthResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    await _firebaseService.signOut();
  }

  // Change password
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('Ntiwinjiye muri sisiteme');
      }

      // Validate input
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return AuthResult.failure('Uzuza amajambo yombi');
      }

      if (newPassword.length < 6) {
        return AuthResult.failure('Ijambo ryibanga rigomba kuba rifite byibura inyuguti 6');
      }

      // Verify current password
      if (!_verifyPassword(currentPassword, _currentUser!.passwordHash)) {
        return AuthResult.failure('Ijambo ryibanga rya none ntikwiye');
      }

      // Hash new password
      final newPasswordHash = _hashPassword(newPassword);

      // Update user
      final updatedUser = _currentUser!.copyWith(passwordHash: newPasswordHash);
      await _firebaseService.updateUserProfile(updatedUser);

      _currentUser = updatedUser;
      await _saveCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Ntibyashobotse guhindura ijambo ryibanga: ${e.toString()}');
    }
  }

  // Create new user account
  Future<AuthResult> createUser({
    required String username,
    required String password,
    required String fullName,
    required app_user.UserRole role,
    String? email,
  }) async {
    try {
      // Validate input
      if (username.trim().isEmpty || password.isEmpty || fullName.trim().isEmpty) {
        return AuthResult.failure('Uzuza amakuru yose');
      }

      if (password.length < 6) {
        return AuthResult.failure('Ijambo ryibanga rigomba kuba rifite byibura inyuguti 6');
      }

      // Check if username already exists
      final existingUser = await _firebaseService.getUserByUsername(username.trim());
      if (existingUser != null) {
        return AuthResult.failure('Iri zina rirasanzwe rikoreshwa');
      }

      // Create user profile
      final newUser = app_user.User(
        username: username.trim(),
        passwordHash: _hashPassword(password),
        fullName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // If email is provided, create Firebase Auth account
      if (email != null && email.isNotEmpty) {
        final credential = await _firebaseService.createUserWithEmailAndPassword(email, password);
        if (credential?.user != null) {
          // Use Firebase Auth UID as user ID
          final userWithId = app_user.User(
            userId: credential!.user!.uid,
            username: username.trim(),
            passwordHash: _hashPassword(password),
            fullName: fullName.trim(),
            role: role,
            createdAt: DateTime.now(),
            isActive: true,
          );
          await _firebaseService.createUserProfile(userWithId);
          return AuthResult.success(userWithId);
        }
      } else {
        // Create user profile without Firebase Auth
        await _firebaseService.createUserProfile(newUser);
        return AuthResult.success(newUser);
      }

      return AuthResult.failure('Ntibyashobotse kurema konti');
    } catch (e) {
      return AuthResult.failure('Ntibyashobotse kurema konti: ${e.toString()}');
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? fullName,
    app_user.UserRole? role,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('Ntiwinjiye muri sisiteme');
      }

      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        role: role,
      );

      await _firebaseService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      await _saveCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Ntibyashobotse kuvugurura profil: ${e.toString()}');
    }
  }

  // Get all users (admin only)
  Future<List<app_user.User>> getAllUsers() async {
    try {
      return await _firebaseService.getAllUsers();
    } catch (e) {
      return [];
    }
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
  Future<void> _saveSession(app_user.User user, bool rememberMe) async {
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
  Future<void> _saveCurrentUser(app_user.User user) async {
    await _storage.write(key: _currentUserKey, value: jsonEncode(user.toMap()));
  }

  // Load current user
  Future<void> _loadCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _currentUserKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = app_user.User.fromMap(userMap);
      }
    } catch (e) {
      // Clear invalid session
      await _clearSession();
    }
  }

  // Check session expiry
  Future<void> _checkSessionExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginString = prefs.getString(_lastLoginKey);
      
      if (lastLoginString != null) {
        final lastLogin = DateTime.parse(lastLoginString);
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        
        // Session expires after configured hours
        if (difference.inHours > AppConfig.sessionTimeoutHours) {
          await logout();
        }
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
    await prefs.remove(_lastLoginKey);
    await prefs.remove(_rememberMeKey);
  }

  // Generate session token
  String _generateSessionToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return _hashPassword('$now-$random');
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String? message;
  final app_user.User? user;

  AuthResult._({required this.success, this.message, this.user});

  factory AuthResult.success(app_user.User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message);
  }
}
