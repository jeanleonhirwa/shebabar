import '../models/product.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'auth_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // Get all products
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    return await _databaseService.getAllProducts(activeOnly: activeOnly);
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    return await _databaseService.getProductsByCategory(category);
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return await getAllProducts();
    }
    return await _databaseService.searchProducts(query.trim());
  }

  // Get product by ID
  Future<Product?> getProductById(int productId) async {
    return await _databaseService.getProductById(productId);
  }

  // Add new product (owner only)
  Future<ProductResult> addProduct({
    required String productName,
    required ProductCategory category,
    required double unitPrice,
    int currentStock = 0,
    int minStockLevel = 5,
  }) async {
    try {
      // Check permissions
      if (!_authService.hasPermission(Permission.manageProducts)) {
        return ProductResult.failure('Ntufite uburenganzira bwo gukora ibicuruzwa');
      }

      // Validate input
      if (productName.trim().isEmpty) {
        return ProductResult.failure('Izina ry\'icyicuruzwa rikenewe');
      }

      if (unitPrice <= 0) {
        return ProductResult.failure('Igiciro kigomba kuba kirenze 0');
      }

      if (currentStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      if (minStockLevel < 0) {
        return ProductResult.failure('Stock ntoya ntishobora kuba munsi ya 0');
      }

      // Check if product name already exists
      final existingProducts = await searchProducts(productName.trim());
      final duplicateProduct = existingProducts.firstWhere(
        (p) => p.productName.toLowerCase() == productName.trim().toLowerCase(),
        orElse: () => Product(
          productName: '',
          category: category,
          unitPrice: 0,
        ),
      );

      if (duplicateProduct.productName.isNotEmpty) {
        return ProductResult.failure(AppConstants.productExists);
      }

      // Create new product
      final product = Product(
        productName: productName.trim(),
        category: category,
        unitPrice: unitPrice,
        currentStock: currentStock,
        minStockLevel: minStockLevel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert product
      final productId = await _databaseService.insertProduct(product);
      final createdProduct = product.copyWith(productId: productId);

      return ProductResult.success(createdProduct);
    } catch (e) {
      return ProductResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Update product (owner only)
  Future<ProductResult> updateProduct(Product product) async {
    try {
      // Check permissions
      if (!_authService.hasPermission(Permission.manageProducts)) {
        return ProductResult.failure('Ntufite uburenganzira bwo guhindura ibicuruzwa');
      }

      // Validate input
      if (product.productName.trim().isEmpty) {
        return ProductResult.failure('Izina ry\'icyicuruzwa rikenewe');
      }

      if (product.unitPrice <= 0) {
        return ProductResult.failure('Igiciro kigomba kuba kirenze 0');
      }

      if (product.currentStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      // Update product with current timestamp
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _databaseService.updateProduct(updatedProduct);

      return ProductResult.success(updatedProduct);
    } catch (e) {
      return ProductResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Archive product (soft delete - owner only)
  Future<ProductResult> archiveProduct(int productId) async {
    try {
      // Check permissions
      if (!_authService.hasPermission(Permission.manageProducts)) {
        return ProductResult.failure('Ntufite uburenganzira bwo gukuraho ibicuruzwa');
      }

      // Get product
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return ProductResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Archive product
      final archivedProduct = product.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateProduct(archivedProduct);

      return ProductResult.success(archivedProduct);
    } catch (e) {
      return ProductResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Restore archived product (owner only)
  Future<ProductResult> restoreProduct(int productId) async {
    try {
      // Check permissions
      if (!_authService.hasPermission(Permission.manageProducts)) {
        return ProductResult.failure('Ntufite uburenganzira bwo gusubiza ibicuruzwa');
      }

      // Get product
      final product = await _databaseService.getProductById(productId);
      if (product == null) {
        return ProductResult.failure('Icyicuruzwa ntikiboneka');
      }

      // Restore product
      final restoredProduct = product.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateProduct(restoredProduct);

      return ProductResult.success(restoredProduct);
    } catch (e) {
      return ProductResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Get products grouped by category
  Future<Map<ProductCategory, List<Product>>> getProductsGroupedByCategory() async {
    final products = await getAllProducts();
    final Map<ProductCategory, List<Product>> groupedProducts = {};

    for (final product in products) {
      if (!groupedProducts.containsKey(product.category)) {
        groupedProducts[product.category] = [];
      }
      groupedProducts[product.category]!.add(product);
    }

    // Sort products within each category
    for (final category in groupedProducts.keys) {
      groupedProducts[category]!.sort((a, b) => a.productName.compareTo(b.productName));
    }

    return groupedProducts;
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isLowStock).toList();
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isOutOfStock).toList();
  }

  // Get critical stock products
  Future<List<Product>> getCriticalStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isCriticalStock).toList();
  }

  // Update product stock (used by stock service)
  Future<ProductResult> updateProductStock(int productId, int newStock) async {
    try {
      if (newStock < 0) {
        return ProductResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      await _databaseService.updateProductStock(productId, newStock);

      final updatedProduct = await _databaseService.getProductById(productId);
      if (updatedProduct == null) {
        return ProductResult.failure('Icyicuruzwa ntikiboneka');
      }

      return ProductResult.success(updatedProduct);
    } catch (e) {
      return ProductResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Get product statistics
  Future<ProductStats> getProductStats() async {
    final products = await getAllProducts();
    
    int totalProducts = products.length;
    int inStockProducts = products.where((p) => p.currentStock > 0).length;
    int lowStockProducts = products.where((p) => p.isLowStock).length;
    int outOfStockProducts = products.where((p) => p.isOutOfStock).length;
    
    double totalStockValue = products.fold(0.0, (sum, p) => sum + p.totalValue);
    
    // Group by category
    Map<ProductCategory, int> categoryCount = {};
    Map<ProductCategory, double> categoryValue = {};
    
    for (final product in products) {
      categoryCount[product.category] = (categoryCount[product.category] ?? 0) + 1;
      categoryValue[product.category] = (categoryValue[product.category] ?? 0.0) + product.totalValue;
    }

    return ProductStats(
      totalProducts: totalProducts,
      inStockProducts: inStockProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      totalStockValue: totalStockValue,
      categoryCount: categoryCount,
      categoryValue: categoryValue,
    );
  }

  // Validate product data
  Future<ValidationResult> validateProduct({
    required String productName,
    required ProductCategory category,
    required double unitPrice,
    required int currentStock,
    required int minStockLevel,
    int? excludeProductId,
  }) async {
    try {
      // Validate product name
      if (productName.trim().isEmpty) {
        return ValidationResult.failure('Izina ry\'icyicuruzwa rikenewe');
      }

      if (productName.trim().length < 2) {
        return ValidationResult.failure('Izina ry\'icyicuruzwa rigomba kuba rifite ibyangombwa 2 byibuze');
      }

      if (productName.trim().length > 50) {
        return ValidationResult.failure('Izina ry\'icyicuruzwa ntirirenze ibyangombwa 50');
      }

      // Check for duplicate name
      final existingProducts = await searchProducts(productName.trim());
      final duplicateProduct = existingProducts.firstWhere(
        (p) => p.productName.toLowerCase() == productName.trim().toLowerCase() &&
               p.productId != excludeProductId,
        orElse: () => Product(
          productName: '',
          category: category,
          unitPrice: 0,
        ),
      );

      if (duplicateProduct.productName.isNotEmpty) {
        return ValidationResult.failure(AppConstants.productExists);
      }

      // Validate price
      if (unitPrice <= 0) {
        return ValidationResult.failure('Igiciro kigomba kuba kirenze 0');
      }

      if (unitPrice > 1000000) {
        return ValidationResult.failure('Igiciro ntikigomba kurenza 1,000,000');
      }

      // Validate stock
      if (currentStock < 0) {
        return ValidationResult.failure('Stock ntishobora kuba munsi ya 0');
      }

      if (currentStock > 100000) {
        return ValidationResult.failure('Stock ntishobora kurenza 100,000');
      }

      // Validate min stock level
      if (minStockLevel < 0) {
        return ValidationResult.failure('Stock ntoya ntishobora kuba munsi ya 0');
      }

      if (minStockLevel > 1000) {
        return ValidationResult.failure('Stock ntoya ntishobora kurenza 1,000');
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Initialize default products if none exist
  Future<void> initializeDefaultProducts() async {
    await _databaseService.initializeDefaultProducts();
  }
}

// Result classes
class ProductResult {
  final bool success;
  final String? message;
  final Product? product;

  ProductResult._(this.success, this.message, this.product);

  factory ProductResult.success(Product product) {
    return ProductResult._(true, null, product);
  }

  factory ProductResult.failure(String message) {
    return ProductResult._(false, message, null);
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

// Product statistics class
class ProductStats {
  final int totalProducts;
  final int inStockProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalStockValue;
  final Map<ProductCategory, int> categoryCount;
  final Map<ProductCategory, double> categoryValue;

  ProductStats({
    required this.totalProducts,
    required this.inStockProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalStockValue,
    required this.categoryCount,
    required this.categoryValue,
  });

  double get stockPercentage => totalProducts > 0 ? (inStockProducts / totalProducts) * 100 : 0.0;
  double get lowStockPercentage => totalProducts > 0 ? (lowStockProducts / totalProducts) * 100 : 0.0;
  double get outOfStockPercentage => totalProducts > 0 ? (outOfStockProducts / totalProducts) * 100 : 0.0;
}
