import '../models/stock_movement.dart';
import '../models/product.dart';
import 'firebase_service.dart';
import 'product_service.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final ProductService _productService = ProductService();

  // Record incoming stock
  Future<StockResult> recordIncoming({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? notes,
    required String userId,
  }) async {
    try {
      // Validate input
      if (quantity <= 0) {
        return StockResult.failure('Umubare ugomba kuba urenze 0');
      }

      if (unitPrice < 0) {
        return StockResult.failure('Igiciro ntikishobora kuba munsi ya 0');
      }

      // Get product to verify it exists
      final product = await _productService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Igicuruzwa ntikiboneka');
      }

      // Create stock movement
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYINJIYE,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: quantity * unitPrice,
        notes: notes,
        userId: userId,
        movementDate: DateTime.now(),
        movementTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Add stock movement (this will also update product stock)
      final movementId = await _firebaseService.addStockMovement(movement);
      final createdMovement = movement.copyWith(movementId: movementId);

      return StockResult.success(createdMovement);
    } catch (e) {
      return StockResult.failure('Ntibyashobotse kwandika stock yinjiye: ${e.toString()}');
    }
  }

  // Record sale
  Future<StockResult> recordSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? notes,
    required String userId,
  }) async {
    try {
      // Validate input
      if (quantity <= 0) {
        return StockResult.failure('Umubare ugomba kuba urenze 0');
      }

      if (unitPrice < 0) {
        return StockResult.failure('Igiciro ntikishobora kuba munsi ya 0');
      }

      // Get product to check stock availability
      final product = await _productService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Igicuruzwa ntikiboneka');
      }

      // Check if enough stock is available
      if (product.currentStock < quantity) {
        return StockResult.failure('Stock ntihagije. Usanzwe ufite: ${product.currentStock}');
      }

      // Create stock movement
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYAGURISHIJWE,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: quantity * unitPrice,
        notes: notes,
        userId: userId,
        movementDate: DateTime.now(),
        movementTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Add stock movement (this will also update product stock)
      final movementId = await _firebaseService.addStockMovement(movement);
      final createdMovement = movement.copyWith(movementId: movementId);

      return StockResult.success(createdMovement);
    } catch (e) {
      return StockResult.failure('Ntibyashobotse kwandika igurisha: ${e.toString()}');
    }
  }

  // Record damaged/spoiled stock
  Future<StockResult> recordDamaged({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? notes,
    required String userId,
  }) async {
    try {
      // Validate input
      if (quantity <= 0) {
        return StockResult.failure('Umubare ugomba kuba urenze 0');
      }

      if (unitPrice < 0) {
        return StockResult.failure('Igiciro ntikishobora kuba munsi ya 0');
      }

      // Get product to check stock availability
      final product = await _productService.getProductById(productId);
      if (product == null) {
        return StockResult.failure('Igicuruzwa ntikiboneka');
      }

      // Check if enough stock is available
      if (product.currentStock < quantity) {
        return StockResult.failure('Stock ntihagije. Usanzwe ufite: ${product.currentStock}');
      }

      // Create stock movement
      final movement = StockMovement(
        productId: productId,
        movementType: MovementType.BYONGEWE,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: quantity * unitPrice,
        notes: notes,
        userId: userId,
        movementDate: DateTime.now(),
        movementTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Add stock movement (this will also update product stock)
      final movementId = await _firebaseService.addStockMovement(movement);
      final createdMovement = movement.copyWith(movementId: movementId);

      return StockResult.success(createdMovement);
    } catch (e) {
      return StockResult.failure('Ntibyashobotse kwandika ibicuruzwa byongewe: ${e.toString()}');
    }
  }

  // Get today's stock movements
  Future<List<StockMovement>> getTodayMovements() async {
    return await _firebaseService.getTodayStockMovements();
  }

  // Get stock movements with filters
  Future<List<StockMovement>> getMovements({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    MovementType? movementType,
    int limit = 100,
  }) async {
    return await _firebaseService.getStockMovements(
      startDate: startDate,
      endDate: endDate,
      productId: productId,
      movementType: movementType,
      limit: limit,
    );
  }

  // Get movements by date range
  Future<List<StockMovement>> getMovementsByDateRange(DateTime startDate, DateTime endDate) async {
    return await _firebaseService.getStockMovements(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _firebaseService.getDashboardStats();
  }

  // Get stock movements summary for a period
  Future<StockSummary> getStockSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final movements = await getMovements(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      int totalIncoming = 0;
      int totalSales = 0;
      int totalDamaged = 0;
      double totalIncomingValue = 0;
      double totalSalesValue = 0;
      double totalDamagedValue = 0;

      for (final movement in movements) {
        switch (movement.movementType) {
          case MovementType.BYINJIYE:
            totalIncoming += movement.quantity;
            totalIncomingValue += movement.totalAmount;
            break;
          case MovementType.BYAGURISHIJWE:
            totalSales += movement.quantity;
            totalSalesValue += movement.totalAmount;
            break;
          case MovementType.BYONGEWE:
            totalDamaged += movement.quantity;
            totalDamagedValue += movement.totalAmount;
            break;
        }
      }

      return StockSummary(
        totalIncoming: totalIncoming,
        totalSales: totalSales,
        totalDamaged: totalDamaged,
        totalIncomingValue: totalIncomingValue,
        totalSalesValue: totalSalesValue,
        totalDamagedValue: totalDamagedValue,
        totalMovements: movements.length,
        netQuantity: totalIncoming - totalSales - totalDamaged,
        netValue: totalIncomingValue - totalSalesValue - totalDamagedValue,
      );
    } catch (e) {
      return StockSummary(
        totalIncoming: 0,
        totalSales: 0,
        totalDamaged: 0,
        totalIncomingValue: 0,
        totalSalesValue: 0,
        totalDamagedValue: 0,
        totalMovements: 0,
        netQuantity: 0,
        netValue: 0,
      );
    }
  }

  // Get top selling products
  Future<List<ProductSalesData>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      final salesMovements = await getMovements(
        startDate: startDate,
        endDate: endDate,
        movementType: MovementType.BYAGURISHIJWE,
        limit: 1000,
      );

      final productSales = <String, ProductSalesData>{};

      for (final movement in salesMovements) {
        final productId = movement.productId;
        
        if (productSales.containsKey(productId)) {
          final existing = productSales[productId]!;
          productSales[productId] = ProductSalesData(
            productId: productId,
            productName: existing.productName,
            totalQuantity: existing.totalQuantity + movement.quantity,
            totalValue: existing.totalValue + movement.totalAmount,
            salesCount: existing.salesCount + 1,
          );
        } else {
          final product = await _productService.getProductById(productId);
          productSales[productId] = ProductSalesData(
            productId: productId,
            productName: product?.productName ?? 'Unknown Product',
            totalQuantity: movement.quantity,
            totalValue: movement.totalAmount,
            salesCount: 1,
          );
        }
      }

      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Get stock movements by product
  Future<List<StockMovement>> getMovementsByProduct(String productId, {int limit = 50}) async {
    return await getMovements(
      productId: productId,
      limit: limit,
    );
  }

  // Get low stock alerts
  Future<List<Product>> getLowStockAlerts() async {
    return await _productService.getLowStockProducts();
  }

  // Get critical stock alerts
  Future<List<Product>> getCriticalStockAlerts() async {
    return await _productService.getCriticalStockProducts();
  }

  // Get out of stock alerts
  Future<List<Product>> getOutOfStockAlerts() async {
    return await _productService.getOutOfStockProducts();
  }

  // Bulk record movements
  Future<BulkStockResult> bulkRecordMovements(List<StockMovement> movements) async {
    final results = <StockResult>[];
    int successCount = 0;
    int failureCount = 0;

    for (final movement in movements) {
      try {
        final movementId = await _firebaseService.addStockMovement(movement);
        final createdMovement = movement.copyWith(movementId: movementId);
        results.add(StockResult.success(createdMovement));
        successCount++;
      } catch (e) {
        results.add(StockResult.failure('Failed to record movement: ${e.toString()}'));
        failureCount++;
      }
    }

    return BulkStockResult(
      results: results,
      successCount: successCount,
      failureCount: failureCount,
      totalCount: movements.length,
    );
  }
}

// Stock result class
class StockResult {
  final bool success;
  final String? message;
  final StockMovement? movement;

  StockResult._({required this.success, this.message, this.movement});

  factory StockResult.success(StockMovement movement) {
    return StockResult._(success: true, movement: movement);
  }

  factory StockResult.failure(String message) {
    return StockResult._(success: false, message: message);
  }
}

// Stock summary class
class StockSummary {
  final int totalIncoming;
  final int totalSales;
  final int totalDamaged;
  final double totalIncomingValue;
  final double totalSalesValue;
  final double totalDamagedValue;
  final int totalMovements;
  final int netQuantity;
  final double netValue;

  StockSummary({
    required this.totalIncoming,
    required this.totalSales,
    required this.totalDamaged,
    required this.totalIncomingValue,
    required this.totalSalesValue,
    required this.totalDamagedValue,
    required this.totalMovements,
    required this.netQuantity,
    required this.netValue,
  });
}

// Product sales data class
class ProductSalesData {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalValue;
  final int salesCount;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalValue,
    required this.salesCount,
  });

  double get averagePrice => salesCount > 0 ? totalValue / totalQuantity : 0.0;
  double get averageQuantityPerSale => salesCount > 0 ? totalQuantity / salesCount : 0.0;
}

// Bulk stock result class
class BulkStockResult {
  final List<StockResult> results;
  final int successCount;
  final int failureCount;
  final int totalCount;

  BulkStockResult({
    required this.results,
    required this.successCount,
    required this.failureCount,
    required this.totalCount,
  });

  bool get hasFailures => failureCount > 0;
  bool get allSuccessful => failureCount == 0;
  double get successRate => totalCount > 0 ? successCount / totalCount : 0.0;
}
