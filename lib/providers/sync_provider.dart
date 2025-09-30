import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/database_service.dart';

class SyncProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
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
  bool get needsSync => _pendingCount > 0;
  
  // Sync status text for UI
  String get syncStatusText {
    if (_isSyncing) {
      return 'Birasync...';
    } else if (!_isOnline) {
      return 'Ntiwunganiye kuri Internet';
    } else if (_pendingCount > 0) {
      return '$_pendingCount ibikeneye sync';
    } else {
      return 'Byose birasync neza';
    }
  }

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

  // Manual sync trigger
  Future<bool> performSync() async {
    if (_isSyncing) {
      return false; // Already syncing
    }

    _setSyncing(true);
    _clearMessages();

    try {
      final success = await _databaseService.performFullSync();
      
      if (success) {
        _setSuccessMessage('Sync yarangiye neza!');
        await _updateSyncStatus();
        return true;
      } else {
        _setErrorMessage('Sync ntiyarangiye. Gerageza nanone.');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Habayeho ikosa mu sync: ${e.toString()}');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  // Force sync (even if offline - will queue for later)
  Future<void> forceSync() async {
    await _updateSyncStatus();
    if (_isOnline) {
      await performSync();
    } else {
      _setErrorMessage('Ntiwunganiye kuri Internet. Sync izakorwa nyuma.');
    }
  }

  // Start automatic periodic sync (every 5 minutes when online)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isOnline && !_isSyncing && _pendingCount > 0) {
        await performSync();
      }
    });
  }

  // Start periodic status updates (every 30 seconds)
  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateSyncStatus();
    });
  }

  // Update sync status from database
  Future<void> _updateSyncStatus() async {
    try {
      final status = await _databaseService.getSyncStatus();
      
      _isOnline = status['isOnline'] as bool;
      _pendingCount = status['pendingCount'] as int;
      _lastSyncTime = status['lastSyncTime'] as String?;
      
      notifyListeners();
    } catch (e) {
      print('Failed to update sync status: $e');
    }
  }

  // Get detailed sync information
  Future<Map<String, dynamic>> getDetailedSyncInfo() async {
    try {
      final pendingData = await _databaseService.getPendingSyncData();
      final status = await _databaseService.getSyncStatus();
      
      return {
        'status': status,
        'pendingData': {
          'users': pendingData['users']?.length ?? 0,
          'products': pendingData['products']?.length ?? 0,
          'movements': pendingData['stock_movements']?.length ?? 0,
          'summaries': pendingData['daily_summaries']?.length ?? 0,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  // Retry failed sync items
  Future<bool> retryFailedSync() async {
    return await performSync();
  }

  // Clear sync queue (use with caution)
  Future<void> clearSyncQueue() async {
    try {
      // Mark all items as synced by updating their sync_status to 1
      final db = await _databaseService.localDatabase;
      await db.transaction((txn) async {
        await txn.update('users', {'sync_status': 1}, where: 'sync_status = 0');
        await txn.update('products', {'sync_status': 1}, where: 'sync_status = 0');
        await txn.update('stock_movements', {'sync_status': 1}, where: 'sync_status = 0');
        await txn.update('daily_summaries', {'sync_status': 1}, where: 'sync_status = 0');
      });
      
      await _updateSyncStatus();
      _setSuccessMessage('Sync queue yarasiwe');
    } catch (e) {
      _setErrorMessage('Ntibyashobotse gusiba sync queue: ${e.toString()}');
    }
  }

  // Check if specific item needs sync
  Future<bool> itemNeedsSync(String table, Map<String, dynamic> where) async {
    try {
      final db = await _databaseService.localDatabase;
      final result = await db.query(
        table,
        where: '${where.keys.map((key) => '$key = ?').join(' AND ')} AND sync_status = 0',
        whereArgs: where.values.toList(),
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Mark specific item for sync
  Future<void> markItemForSync(String table, Map<String, dynamic> where) async {
    try {
      await _databaseService.markForSync(table, where);
      await _updateSyncStatus();
      _setSuccessMessage('Item yarongewe kuri sync');
    } catch (e) {
      _setErrorMessage('Ntibyashobotse kuronga item kuri sync: ${e.toString()}');
    }
  }

  // Get sync history (last 10 sync attempts)
  Future<List<Map<String, dynamic>>> getSyncHistory() async {
    try {
      final db = await _databaseService.localDatabase;
      
      // Create sync_history table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sync_time TEXT NOT NULL,
          success INTEGER NOT NULL,
          items_synced INTEGER NOT NULL,
          error_message TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      
      final result = await db.query(
        'sync_history',
        orderBy: 'created_at DESC',
        limit: 10,
      );
      
      return result;
    } catch (e) {
      return [];
    }
  }


  // Helper methods
  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Get sync priority (higher number = higher priority)
  int getSyncPriority() {
    if (!_isOnline) return 0;
    if (_isSyncing) return 1;
    if (_pendingCount > 10) return 5;
    if (_pendingCount > 5) return 4;
    if (_pendingCount > 0) return 3;
    return 2;
  }

  // Get user-friendly sync status
  String getUserFriendlyStatus() {
    if (_isSyncing) {
      return 'Birasync... Tegereza gato.';
    } else if (!_isOnline) {
      return 'Ntiwunganiye kuri Internet. Sync izakorwa nyuma.';
    } else if (_pendingCount > 0) {
      return 'Hari $_pendingCount ibikeneye sync. Kanda hano kugirango usync.';
    } else if (_lastSyncTime != null) {
      final lastSync = DateTime.tryParse(_lastSyncTime!);
      if (lastSync != null) {
        final difference = DateTime.now().difference(lastSync);
        if (difference.inMinutes < 5) {
          return 'Sync yarangiye vuba aha (${difference.inMinutes} min)';
        } else if (difference.inHours < 1) {
          return 'Sync yarangiye ${difference.inMinutes} min ashize';
        } else if (difference.inDays < 1) {
          return 'Sync yarangiye ${difference.inHours} h ashize';
        } else {
          return 'Sync yarangiye ${difference.inDays} day(s) ashize';
        }
      }
    }
    return 'Sync iri ready';
  }
}
