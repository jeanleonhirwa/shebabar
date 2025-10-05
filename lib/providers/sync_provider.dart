import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/firebase_service.dart';

class SyncProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Private state variables
  bool _isOnline = false;
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastSyncTime;
  String? _errorMessage;
  String? _successMessage;
  
  Timer? _syncTimer;
  Timer? _statusTimer;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Initialize sync provider
  Future<void> initialize() async {
    await _updateSyncStatus();
    _startPeriodicSync();
    _startStatusUpdates();
  }

  // Dispose resources
  @override
  void dispose() {
    _syncTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  // Perform full sync (Firebase handles sync automatically)
  Future<bool> performFullSync() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (_isOnline) {
        _successMessage = 'Connected to Firebase - data syncs automatically';
        _lastSyncTime = DateTime.now().toIso8601String();
        _pendingCount = 0;
      } else {
        _errorMessage = 'No internet connection';
      }
      
      notifyListeners();
      return _isOnline;
    } catch (e) {
      _errorMessage = 'Sync error: ${e.toString()}';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Force sync (check connectivity)
  Future<void> forceSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    await _updateSyncStatus();
    
    if (_isOnline) {
      await performFullSync();
    } else {
      _setErrorMessage('Ntiwunganiye kuri Internet. Sync izakorwa nyuma.');
    }
    
    _isSyncing = false;
    notifyListeners();
  }

  // Start automatic periodic sync (every 5 minutes when online)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing && _pendingCount > 0) {
        performFullSync();
      }
    });
  }

  // Start status updates (every 30 seconds)
  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateSyncStatus();
    });
  }

  // Update sync status
  Future<void> _updateSyncStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      _pendingCount = 0; // Firebase handles sync automatically
      _lastSyncTime = DateTime.now().toIso8601String();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update sync status: $e');
      }
    }
  }

  // Get detailed sync information
  Future<Map<String, dynamic>> getDetailedSyncInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      return {
        'isOnline': isOnline,
        'isSyncing': _isSyncing,
        'pendingCount': 0, // Firebase handles sync automatically
        'lastSyncTime': _lastSyncTime,
        'errorMessage': _errorMessage,
        'successMessage': _successMessage,
        'syncStatus': isOnline ? 'Connected' : 'Offline',
        'connectionType': connectivityResult.toString().split('.').last,
      };
    } catch (e) {
      return {
        'isOnline': false,
        'isSyncing': false,
        'pendingCount': 0,
        'lastSyncTime': null,
        'errorMessage': 'Failed to get sync info: ${e.toString()}',
        'successMessage': null,
        'syncStatus': 'Error',
        'connectionType': 'none',
      };
    }
  }

  // Get user-friendly status message
  String getUserFriendlyStatus() {
    if (_isSyncing) {
      return 'Gusync...';
    }
    
    if (!_isOnline) {
      return 'Ntiwunganiye kuri Internet';
    }
    
    if (_pendingCount > 0) {
      return 'Hari amakuru $pendingCount ategereje gusync';
    }
    
    return 'Byose birasync neza';
  }

  // Get status color
  Color getStatusColor() {
    if (_isSyncing) {
      return Colors.orange;
    }
    
    if (!_isOnline) {
      return Colors.red;
    }
    
    if (_pendingCount > 0) {
      return Colors.amber;
    }
    
    return Colors.green;
  }

  // Get status icon
  IconData getStatusIcon() {
    if (_isSyncing) {
      return Icons.sync;
    }
    
    if (!_isOnline) {
      return Icons.cloud_off;
    }
    
    if (_pendingCount > 0) {
      return Icons.cloud_upload;
    }
    
    return Icons.cloud_done;
  }

  // Perform sync (alias for performFullSync)
  Future<bool> performSync() async {
    return await performFullSync();
  }

  // Set syncing state
  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  // Set error message
  void _setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  // Set success message
  void _setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear messages
  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingCount': _pendingCount,
      'lastSyncTime': _lastSyncTime,
      'hasError': _errorMessage != null,
      'hasSuccess': _successMessage != null,
    };
  }
}
