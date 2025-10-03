import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/daily_summary.dart';
import '../utils/helpers.dart';
import 'database_service.dart';
import 'auth_service.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // Record incoming stock
  Future<StockResult> recordIncoming({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return StockResult.failure('Ntujyewe muri sisitemu');
      }

      // Validate quantity
      if (quantity <= 0) {
        return StockResult.failure('Ingano igomba kuba irenze 0');
      }

      // Get product
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Create stock movement
      final now = DateTime.now();
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYINJIYE,
        quantity: quantity,
        unitPrice: product.unitPrice,
        totalAmount: quantity * product.unitPrice,
        notes: notes,
        userId: currentUser.userId!,
        movementDate: now,
        movementTime: now,
      );

      // Record movement (this will also update product stock)
      final movementId = await _databaseService.insertStockMovement(movement);
      final recordedMovement = movement.copyWith(movementId: movementId);

      // Update daily summary
      await _updateDailySummary(now);

      return StockResult.success(recordedMovement);
    } catch (e) {
      return StockResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Record sold stock
  Future<StockResult> recordSale({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return StockResult.failure('Ntujyewe muri sisitemu');
      }

      // Validate quantity
      if (quantity <= 0) {
        return StockResult.failure('Ingano igomba kuba irenze 0');
      }

      // Get product
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Check if enough stock available
      if (product.currentStock < quantity) {
        return StockResult.failure(
          'Stock ntihagije. Biri muri stock: ${product.currentStock}'
        );
      }

      // Create stock movement
      final now = DateTime.now();
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYAGURISHIJWE,
        quantity: quantity,
        unitPrice: product.unitPrice,
        totalAmount: quantity * product.unitPrice,
        notes: notes,
        userId: currentUser.userId!,
        movementDate: now,
        movementTime: now,
      );

      // Record movement (this will also update product stock)
      final movementId = await _databaseService.insertStockMovement(movement);
      final recordedMovement = movement.copyWith(movementId: movementId);

      // Update daily summary
      await _updateDailySummary(now);

      return StockResult.success(recordedMovement);
    } catch (e) {
      return StockResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Record damaged stock
  Future<StockResult> recordDamaged({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return StockResult.failure('Ntujyewe muri sisitemu');
      }

      // Validate quantity
      if (quantity <= 0) {
        return StockResult.failure('Ingano igomba kuba irenze 0');
      }

      // Get product
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Check if enough stock available
      if (product.currentStock < quantity) {
        return StockResult.failure(
          'Stock ntihagije. Biri muri stock: ${product.currentStock}'
        );
      }

      // Create stock movement
      final now = DateTime.now();
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYONGEWE,
        quantity: quantity,
        unitPrice: product.unitPrice,
        totalAmount: quantity * product.unitPrice,
        notes: notes,
        userId: currentUser.userId!,
        movementDate: now,
        movementTime: now,
      );

      // Record movement (this will also update product stock)
      final movementId = await _databaseService.insertStockMovement(movement);
      final recordedMovement = movement.copyWith(movementId: movementId);

      // Update daily summary
      await _updateDailySummary(now);

      return StockResult.success(recordedMovement);
    } catch (e) {
      return StockResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Get today's stock movements
  Future<List<StockMovement>> getTodayMovements() async {
    return await _databaseService.getTodayStockMovements();
  }

  // Get stock movements by type for today
  Future<List<StockMovement>> getTodayMovementsByType(MovementType type) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await _databaseService.getStockMovements(
      startDate: startOfDay,
      endDate: endOfDay,
      movementType: type,
    );
  }

  // Get stock movements for a date range
  Future<List<StockMovement>> getMovements({
    DateTime? startDate,
    DateTime? endDate,
    int? productId,
    MovementType? movementType,
  }) async {
    return await _databaseService.getStockMovements(
      startDate: startDate,
      endDate: endDate,
      productId: productId,
      movementType: movementType,
    );
  }

  // Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    final stats = await _databaseService.getDashboardStats();
    
    return DashboardStats(
      itemsInStock: stats['itemsInStock'] as int,
      stockValue: (stats['stockValue'] as num).toDouble(),
      todaySalesCount: stats['todaySalesCount'] as int,
      todaySalesAmount: (stats['todaySalesAmount'] as num).toDouble(),
      todayDamagedCount: stats['todayDamagedCount'] as int,
      todayIncomingCount: stats['todayIncomingCount'] as int? ?? 0,
      todayDamageAmount: (stats['todayDamageAmount'] as num?)?.toDouble() ?? 0.0,
      todayProfit: (stats['todayProfit'] as num?)?.toDouble() ?? 0.0,
      lowStockProducts: stats['lowStockProducts'] as List<Product>,
    );
  }

  // Update daily summary
  Future<void> _updateDailySummary(DateTime date) async {
    final summaryDate = DateTime(date.year, date.month, date.day);
    final startOfDay = summaryDate;
    final endOfDay = summaryDate.add(const Duration(days: 1));

    // Get today's movements
    final movements = await _databaseService.getStockMovements(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    // Calculate totals
    int totalSalesQuantity = 0;
    double totalSalesAmount = 0.0;
    int totalIncomingQuantity = 0;
    int totalDamagedQuantity = 0;
    double totalDamagedAmount = 0.0;

    for (final movement in movements) {
      switch (movement.movementType) {
        case MovementType.BYAGURISHIJWE:
          totalSalesQuantity += movement.quantity;
          totalSalesAmount += movement.totalAmount;
          break;
        case MovementType.BYINJIYE:
          totalIncomingQuantity += movement.quantity;
          break;
        case MovementType.BYONGEWE:
          totalDamagedQuantity += movement.quantity;
          totalDamagedAmount += movement.totalAmount;
          break;
      }
    }

    // Calculate closing stock value
    final products = await _databaseService.getAllProducts();
    double closingStockValue = 0.0;
    for (final product in products) {
      closingStockValue += product.totalValue;
    }

    // Create or update daily summary
    final summary = DailySummary(
      summaryDate: summaryDate,
      totalSalesQuantity: totalSalesQuantity,
      totalSalesAmount: totalSalesAmount,
      totalIncomingQuantity: totalIncomingQuantity,
      totalDamagedQuantity: totalDamagedQuantity,
      totalDamagedAmount: totalDamagedAmount,
      closingStockValue: closingStockValue,
      updatedAt: DateTime.now(),
    );

    // This would need to be implemented in DatabaseService
    // await _databaseService.insertOrUpdateDailySummary(summary);
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final products = await _databaseService.getAllProducts();
    return products.where((product) => product.isLowStock).toList();
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final products = await _databaseService.getAllProducts();
    return products.where((product) => product.isOutOfStock).toList();
  }

  // Calculate stock value by category
  Future<Map<ProductCategory, double>> getStockValueByCategory() async {
    final products = await _databaseService.getAllProducts();
    final Map<ProductCategory, double> categoryValues = {};

    for (final product in products) {
      categoryValues[product.category] = 
          (categoryValues[product.category] ?? 0.0) + product.totalValue;
    }

    return categoryValues;
  }

  // Get best selling products
  Future<List<ProductSalesStats>> getBestSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final movements = await _databaseService.getStockMovements(
      startDate: startDate,
      endDate: endDate,
      movementType: MovementType.BYAGURISHIJWE,
    );

    final Map<int, ProductSalesStats> salesMap = {};

    for (final movement in movements) {
      if (salesMap.containsKey(movement.productId)) {
        final existing = salesMap[movement.productId]!;
        salesMap[movement.productId] = ProductSalesStats(
          productId: existing.productId,
          productName: existing.productName,
          quantitySold: existing.quantitySold + movement.quantity,
          totalAmount: existing.totalAmount + movement.totalAmount,
        );
      } else {
        final product = await _databaseService.getProductById(movement.productId);
        if (product != null) {
          salesMap[movement.productId] = ProductSalesStats(
            productId: movement.productId,
            productName: product.productName,
            quantitySold: movement.quantity,
            totalAmount: movement.totalAmount,
          );
        }
      }
    }

    final salesList = salesMap.values.toList();
    salesList.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return salesList.take(limit).toList();
  }

  // Validate stock movement
  Future<ValidationResult> validateStockMovement({
    required int productId,
    required MovementType movementType,
    required int quantity,
  }) async {
    try {
      // Check if product exists
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return ValidationResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Check if product is active
      if (!product.isActive) {
        return ValidationResult.failure('Iki cyicuruzwa ntikiri gikora');
      }

      // Validate quantity
      if (quantity <= 0) {
        return ValidationResult.failure('Ingano igomba kuba irenze 0');
      }

      if (quantity > 10000) {
        return ValidationResult.failure('Ingano ntishobora kurenza 10,000');
      }

      // For sales and damaged items, check available stock
      if (movementType == MovementType.BYAGURISHIJWE || 
          movementType == MovementType.BYONGEWE) {
        if (product.currentStock < quantity) {
          return ValidationResult.failure(
            'Stock ntihagije. Biri muri stock: ${product.currentStock}'
          );
        }
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }
}

// Result classes
class StockResult {
  final bool success;
  final String? message;
  final StockMovement? movement;

  StockResult._(this.success, this.message, this.movement);

  factory StockResult.success(StockMovement movement) {
    return StockResult._(true, null, movement);
  }

  factory StockResult.failure(String message) {
    return StockResult._(false, message, null);
  }
}

class ValidationResult {
  final bool success;
  final String? message;

  ValidationResult._(this.success, this.message);

  factory ValidationResult.success() {
    return ValidationResult._(true, null);
  }

  factory ValidationResult.failure(String message) {
    return ValidationResult._(false, message);
  }
}

// Dashboard statistics class
class DashboardStats {
  final int itemsInStock;
  final double stockValue;
  final int todaySalesCount;
  final double todaySalesAmount;
  final int todayDamagedCount;
  final int todayIncomingCount;
  final double todayDamageAmount;
  final double todayProfit;
  final List<Product> lowStockProducts;

  DashboardStats({
    required this.itemsInStock,
    required this.stockValue,
    required this.todaySalesCount,
    required this.todaySalesAmount,
    required this.todayDamagedCount,
    required this.todayIncomingCount,
    required this.todayDamageAmount,
    required this.todayProfit,
    required this.lowStockProducts,
  });
}

// Product sales statistics
class ProductSalesStats {
  final int productId;
  final String productName;
  final int quantitySold;
  final double totalAmount;

  ProductSalesStats({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalAmount,
  });

  double get averagePrice => quantitySold > 0 ? totalAmount / quantitySold : 0.0;
}
