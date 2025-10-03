import '../models/product.dart';
import 'firebase_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Get all products
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    return await _firebaseService.getAllProducts(activeOnly: activeOnly);
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    return await _firebaseService.getProductsByCategory(category);
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return await getAllProducts();
    }
    return await _firebaseService.searchProducts(query);
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    return await _firebaseService.getProductById(productId);
  }

  // Get products by category name (string)
  Future<List<Product>> getProductsByCategoryName(String categoryName) async {
    try {
      final category = ProductCategory.values.firstWhere(
        (e) => e.toString().split('.').last == categoryName,
      );
      return await getProductsByCategory(category);
    } catch (e) {
      return [];
    }
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product.isLowStock).toList();
  }

  // Get critical stock products
  Future<List<Product>> getCriticalStockProducts() async {
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product.isCriticalStock).toList();
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product.isOutOfStock).toList();
  }

  // Add new product
  Future<ProductResult> addProduct({
    required String productName,
    required ProductCategory category,
    required double unitPrice,
    int currentStock = 0,
    int minStockLevel = 5,
  }) async {
    try {
      // Validate input
      if (productName.trim().isEmpty) {
        return ProductResult.failure('Izina ry\'igicuruzwa kirakenewe');
      }

      if (unitPrice <= 0) {
        return ProductResult.failure('Igiciro kigomba kuba kirenze 0');
      }

      if (currentStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      if (minStockLevel < 0) {
        return ProductResult.failure('Urwego rw\'ibanze rwa stock ntirushobora kuba munsi ya 0');
      }

      // Check if product with same name already exists
      final existingProducts = await searchProducts(productName.trim());
      final duplicateProduct = existingProducts.firstWhere(
        (product) => product.productName.toLowerCase() == productName.trim().toLowerCase(),
        orElse: () => Product(
          productName: '',
          category: category,
          unitPrice: 0,
        ),
      );

      if (duplicateProduct.productName.isNotEmpty) {
        return ProductResult.failure('Igicuruzwa gifite iri zina kirasanzwe kibaho');
      }

      // Create new product
      final newProduct = Product(
        productName: productName.trim(),
        category: category,
        unitPrice: unitPrice,
        currentStock: currentStock,
        minStockLevel: minStockLevel,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productId = await _firebaseService.addProduct(newProduct);
      final createdProduct = newProduct.copyWith(productId: productId);

      return ProductResult.success(createdProduct);
    } catch (e) {
      return ProductResult.failure('Ntibyashobotse kongeramo igicuruzwa: ${e.toString()}');
    }
  }

  // Update product
  Future<ProductResult> updateProduct(Product product) async {
    try {
      if (product.productId == null) {
        return ProductResult.failure('ID y\'igicuruzwa irakenewe');
      }

      // Validate input
      if (product.productName.trim().isEmpty) {
        return ProductResult.failure('Izina ry\'igicuruzwa kirakenewe');
      }

      if (product.unitPrice <= 0) {
        return ProductResult.failure('Igiciro kigomba kuba kirenze 0');
      }

      if (product.currentStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      if (product.minStockLevel < 0) {
        return ProductResult.failure('Urwego rw\'ibanze rwa stock ntirushobora kuba munsi ya 0');
      }

      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _firebaseService.updateProduct(updatedProduct);

      return ProductResult.success(updatedProduct);
    } catch (e) {
      return ProductResult.failure('Ntibyashobotse kuvugurura igicuruzwa: ${e.toString()}');
    }
  }

  // Update product stock
  Future<ProductResult> updateProductStock(String productId, int newStock) async {
    try {
      if (newStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      await _firebaseService.updateProductStock(productId, newStock);
      
      // Get updated product
      final updatedProduct = await getProductById(productId);
      if (updatedProduct != null) {
        return ProductResult.success(updatedProduct);
      } else {
        return ProductResult.failure('Igicuruzwa ntikiboneka');
      }
    } catch (e) {
      return ProductResult.failure('Ntibyashobotse kuvugurura stock: ${e.toString()}');
    }
  }

  // Deactivate product (soft delete)
  Future<ProductResult> deactivateProduct(String productId) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        return ProductResult.failure('Igicuruzwa ntikiboneka');
      }

      final deactivatedProduct = product.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateProduct(deactivatedProduct);
      return ProductResult.success(deactivatedProduct);
    } catch (e) {
      return ProductResult.failure('Ntibyashobotse gufunga igicuruzwa: ${e.toString()}');
    }
  }

  // Reactivate product
  Future<ProductResult> reactivateProduct(String productId) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        return ProductResult.failure('Igicuruzwa ntikiboneka');
      }

      final reactivatedProduct = product.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateProduct(reactivatedProduct);
      return ProductResult.success(reactivatedProduct);
    } catch (e) {
      return ProductResult.failure('Ntibyashobotse gufungura igicuruzwa: ${e.toString()}');
    }
  }

  // Get products summary
  Future<ProductsSummary> getProductsSummary() async {
    try {
      final allProducts = await getAllProducts(activeOnly: false);
      final activeProducts = allProducts.where((p) => p.isActive).toList();
      final inactiveProducts = allProducts.where((p) => !p.isActive).toList();
      final lowStockProducts = activeProducts.where((p) => p.isLowStock).toList();
      final criticalStockProducts = activeProducts.where((p) => p.isCriticalStock).toList();
      final outOfStockProducts = activeProducts.where((p) => p.isOutOfStock).toList();

      double totalValue = 0;
      int totalStock = 0;

      for (final product in activeProducts) {
        totalValue += product.totalValue;
        totalStock += product.currentStock;
      }

      return ProductsSummary(
        totalProducts: allProducts.length,
        activeProducts: activeProducts.length,
        inactiveProducts: inactiveProducts.length,
        lowStockProducts: lowStockProducts.length,
        criticalStockProducts: criticalStockProducts.length,
        outOfStockProducts: outOfStockProducts.length,
        totalStockValue: totalValue,
        totalStockQuantity: totalStock,
      );
    } catch (e) {
      return ProductsSummary(
        totalProducts: 0,
        activeProducts: 0,
        inactiveProducts: 0,
        lowStockProducts: 0,
        criticalStockProducts: 0,
        outOfStockProducts: 0,
        totalStockValue: 0,
        totalStockQuantity: 0,
      );
    }
  }

  // Get products by stock status
  Future<List<Product>> getProductsByStockStatus(StockStatus status) async {
    final allProducts = await getAllProducts();
    
    switch (status) {
      case StockStatus.inStock:
        return allProducts.where((p) => !p.isOutOfStock && !p.isLowStock).toList();
      case StockStatus.lowStock:
        return allProducts.where((p) => p.isLowStock && !p.isCriticalStock).toList();
      case StockStatus.criticalStock:
        return allProducts.where((p) => p.isCriticalStock && !p.isOutOfStock).toList();
      case StockStatus.outOfStock:
        return allProducts.where((p) => p.isOutOfStock).toList();
    }
  }

  // Bulk update stock levels
  Future<BulkUpdateResult> bulkUpdateStock(Map<String, int> stockUpdates) async {
    final results = <String, ProductResult>{};
    int successCount = 0;
    int failureCount = 0;

    for (final entry in stockUpdates.entries) {
      final productId = entry.key;
      final newStock = entry.value;
      
      final result = await updateProductStock(productId, newStock);
      results[productId] = result;
      
      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }

    return BulkUpdateResult(
      results: results,
      successCount: successCount,
      failureCount: failureCount,
      totalCount: stockUpdates.length,
    );
  }

  // Initialize default products if none exist
  Future<void> initializeDefaultProducts() async {
    await _firebaseService.initializeDefaultProducts();
  }

  // Get categories with product counts
  Future<Map<ProductCategory, int>> getCategoryCounts() async {
    final allProducts = await getAllProducts();
    final categoryCounts = <ProductCategory, int>{};
    
    for (final category in ProductCategory.values) {
      categoryCounts[category] = allProducts
          .where((product) => product.category == category)
          .length;
    }
    
    return categoryCounts;
  }
}

// Product result class
class ProductResult {
  final bool success;
  final String? message;
  final Product? product;

  ProductResult._({required this.success, this.message, this.product});

  factory ProductResult.success(Product product) {
    return ProductResult._(success: true, product: product);
  }

  factory ProductResult.failure(String message) {
    return ProductResult._(success: false, message: message);
  }
}

// Products summary class
class ProductsSummary {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int lowStockProducts;
  final int criticalStockProducts;
  final int outOfStockProducts;
  final double totalStockValue;
  final int totalStockQuantity;

  ProductsSummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.lowStockProducts,
    required this.criticalStockProducts,
    required this.outOfStockProducts,
    required this.totalStockValue,
    required this.totalStockQuantity,
  });
}

// Stock status enum
enum StockStatus {
  inStock,
  lowStock,
  criticalStock,
  outOfStock,
}

// Bulk update result class
class BulkUpdateResult {
  final Map<String, ProductResult> results;
  final int successCount;
  final int failureCount;
  final int totalCount;

  BulkUpdateResult({
    required this.results,
    required this.successCount,
    required this.failureCount,
    required this.totalCount,
  });

  bool get hasFailures => failureCount > 0;
  bool get allSuccessful => failureCount == 0;
  double get successRate => totalCount > 0 ? successCount / totalCount : 0.0;
}
