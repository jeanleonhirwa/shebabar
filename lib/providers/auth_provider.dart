import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOwner => _currentUser?.role == UserRole.owner;
  bool get isEmployee => _currentUser?.role == UserRole.employee;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      _clearError();
    } catch (e) {
      _setError('Habayeho ikosa mu gutangiza sisitemu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.login(username, password, rememberMe: rememberMe);
      
      if (result.success) {
        _currentUser = result.user;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Habayeho ikosa');
        return false;
      }
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _clearError();
    } catch (e) {
      _setError('Habayeho ikosa mu gusohoka: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.changePassword(currentPassword, newPassword);
      
      if (result.success) {
        _currentUser = result.user;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Habayeho ikosa');
        return false;
      }
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create new user (owner only)
  Future<bool> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    if (!hasPermission(Permission.manageUsers)) {
      _setError('Ntufite uburenganzira bwo gukora abakozi');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.createUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
      );
      
      if (result.success) {
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Habayeho ikosa');
        return false;
      }
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.updateUser(user);
      
      if (result.success) {
        // Update current user if it's the same user
        if (_currentUser?.userId == user.userId) {
          _currentUser = result.user;
        }
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Habayeho ikosa');
        return false;
      }
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get all users (owner only)
  Future<List<User>> getAllUsers() async {
    if (!hasPermission(Permission.manageUsers)) {
      return [];
    }
    
    try {
      return await _authService.getAllUsers();
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka abakozi: ${e.toString()}');
      return [];
    }
  }

  // Check permissions
  bool hasPermission(Permission permission) {
    return _authService.hasPermission(permission);
  }

  // Check auto-login
  Future<bool> checkAutoLogin() async {
    _setLoading(true);
    try {
      final hasAutoLogin = await _authService.checkAutoLogin();
      if (hasAutoLogin) {
        _currentUser = _authService.currentUser;
        notifyListeners();
      }
      return hasAutoLogin;
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Get user display name
  String get userDisplayName {
    if (_currentUser == null) return '';
    return _currentUser!.fullName;
  }

  // Get user role display name
  String get userRoleDisplayName {
    if (_currentUser == null) return '';
    return _currentUser!.role.displayName;
  }

  // Check if user can perform specific actions
  bool get canManageProducts => hasPermission(Permission.manageProducts);
  bool get canManageUsers => hasPermission(Permission.manageUsers);
  bool get canViewDetailedReports => hasPermission(Permission.viewDetailedReports);
  bool get canExportReports => hasPermission(Permission.exportReports);
  bool get canRecordStock => hasPermission(Permission.recordStock);
  bool get canViewDashboard => hasPermission(Permission.viewDashboard);
}
