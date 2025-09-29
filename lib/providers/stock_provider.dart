import 'package:flutter/foundation.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';
import '../utils/constants.dart';

class StockProvider extends ChangeNotifier {
  final StockService _stockService = StockService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  List<StockMovement> _todayMovements = [];
  List<StockMovement> _incomingMovements = [];
  List<StockMovement> _soldMovements = [];
  List<StockMovement> _damagedMovements = [];
  
  DashboardStats? _dashboardStats;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<StockMovement> get todayMovements => _todayMovements;
  List<StockMovement> get incomingMovements => _incomingMovements;
  List<StockMovement> get soldMovements => _soldMovements;
  List<StockMovement> get damagedMovements => _damagedMovements;
  DashboardStats? get dashboardStats => _dashboardStats;

  // Initialize provider
  Future<void> initialize() async {
    await loadTodayMovements();
    await loadDashboardStats();
  }

  // Record incoming stock
  Future<bool> recordIncoming({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _stockService.recordIncoming(
        productId: productId,
        quantity: quantity,
        notes: notes,
      );
      
      if (result.success) {
        _setSuccessMessage(AppConstants.saved);
        await _refreshData();
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

  // Record sale
  Future<bool> recordSale({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _stockService.recordSale(
        productId: productId,
        quantity: quantity,
        notes: notes,
      );
      
      if (result.success) {
        _setSuccessMessage(AppConstants.saved);
        await _refreshData();
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

  // Record damaged stock
  Future<bool> recordDamaged({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _stockService.recordDamaged(
        productId: productId,
        quantity: quantity,
        notes: notes,
      );
      
      if (result.success) {
        _setSuccessMessage(AppConstants.saved);
        await _refreshData();
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

  // Load today's movements
  Future<void> loadTodayMovements() async {
    try {
      _todayMovements = await _stockService.getTodayMovements();
      
      // Filter movements by type
      _incomingMovements = _todayMovements
          .where((m) => m.movementType == MovementType.BYINJIYE)
          .toList();
      
      _soldMovements = _todayMovements
          .where((m) => m.movementType == MovementType.BYAGURISHIJWE)
          .toList();
      
      _damagedMovements = _todayMovements
          .where((m) => m.movementType == MovementType.BYONGEWE)
          .toList();
      
      // Sort by time (most recent first)
      _incomingMovements.sort((a, b) => b.movementTime.compareTo(a.movementTime));
      _soldMovements.sort((a, b) => b.movementTime.compareTo(a.movementTime));
      _damagedMovements.sort((a, b) => b.movementTime.compareTo(a.movementTime));
      
      notifyListeners();
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka ibikorwa: ${e.toString()}');
    }
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _stockService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka imibare: ${e.toString()}');
    }
  }

  // Get movements for date range
  Future<List<StockMovement>> getMovements({
    DateTime? startDate,
    DateTime? endDate,
    int? productId,
    MovementType? movementType,
  }) async {
    try {
      return await _stockService.getMovements(
        startDate: startDate,
        endDate: endDate,
        productId: productId,
        movementType: movementType,
      );
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka ibikorwa: ${e.toString()}');
      return [];
    }
  }

  // Validate stock movement
  Future<bool> validateStockMovement({
    required int productId,
    required MovementType movementType,
    required int quantity,
  }) async {
    try {
      final result = await _stockService.validateStockMovement(
        productId: productId,
        movementType: movementType,
        quantity: quantity,
      );
      
      if (!result.success) {
        _setError(result.message ?? 'Habayeho ikosa');
        return false;
      }
      
      return true;
    } catch (e) {
      _setError('Habayeho ikosa: ${e.toString()}');
      return false;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await _refreshData();
  }

  // Private helper methods
  Future<void> _refreshData() async {
    await Future.wait([
      loadTodayMovements(),
      loadDashboardStats(),
    ]);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Clear messages manually
  void clearMessages() {
    _clearMessages();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  // Get summary statistics
  Map<String, dynamic> get todaySummary {
    int totalIncoming = _incomingMovements.fold(0, (sum, m) => sum + m.quantity);
    int totalSold = _soldMovements.fold(0, (sum, m) => sum + m.quantity);
    int totalDamaged = _damagedMovements.fold(0, (sum, m) => sum + m.quantity);
    
    double totalSalesValue = _soldMovements.fold(0.0, (sum, m) => sum + m.totalAmount);
    double totalDamageValue = _damagedMovements.fold(0.0, (sum, m) => sum + m.totalAmount);
    
    return {
      'totalIncoming': totalIncoming,
      'totalSold': totalSold,
      'totalDamaged': totalDamaged,
      'totalSalesValue': totalSalesValue,
      'totalDamageValue': totalDamageValue,
      'totalMovements': _todayMovements.length,
    };
  }

  // Get movements count by type
  int getMovementsCountByType(MovementType type) {
    switch (type) {
      case MovementType.BYINJIYE:
        return _incomingMovements.length;
      case MovementType.BYAGURISHIJWE:
        return _soldMovements.length;
      case MovementType.BYONGEWE:
        return _damagedMovements.length;
    }
  }

  // Get movements by type
  List<StockMovement> getMovementsByType(MovementType type) {
    switch (type) {
      case MovementType.BYINJIYE:
        return _incomingMovements;
      case MovementType.BYAGURISHIJWE:
        return _soldMovements;
      case MovementType.BYONGEWE:
        return _damagedMovements;
    }
  }

  // Check if there are any movements today
  bool get hasMovementsToday => _todayMovements.isNotEmpty;

  // Get latest movement
  StockMovement? get latestMovement {
    if (_todayMovements.isEmpty) return null;
    
    final sortedMovements = List<StockMovement>.from(_todayMovements);
    sortedMovements.sort((a, b) => b.movementTime.compareTo(a.movementTime));
    
    return sortedMovements.first;
  }

  // Get movement type counts for today
  Map<MovementType, int> get movementTypeCounts {
    return {
      MovementType.BYINJIYE: _incomingMovements.length,
      MovementType.BYAGURISHIJWE: _soldMovements.length,
      MovementType.BYONGEWE: _damagedMovements.length,
    };
  }
}
