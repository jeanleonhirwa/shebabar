import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Map<ProductCategory, List<Product>> _groupedProducts = {};
  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  Map<ProductCategory, List<Product>> get groupedProducts => _groupedProducts;
  String get searchQuery => _searchQuery;
  ProductCategory? get selectedCategory => _selectedCategory;

  // Initialize provider
  Future<void> initialize() async {
    await loadProducts();
  }

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      _products = await _productService.getAllProducts();
      await _updateGroupedProducts();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka ibicuruzwa: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new product
  Future<bool> addProduct({
    required String productName,
    required ProductCategory category,
    required double unitPrice,
    int currentStock = 0,
    int minStockLevel = 5,
  }) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _productService.addProduct(
        productName: productName,
        category: category,
        unitPrice: unitPrice,
        currentStock: currentStock,
        minStockLevel: minStockLevel,
      );
      
      if (result.success) {
        _setSuccessMessage(AppConstants.saved);
        await loadProducts(); // Refresh the list
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

  // Update product
  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _productService.updateProduct(product);
      
      if (result.success) {
        _setSuccessMessage(AppConstants.saved);
        await loadProducts(); // Refresh the list
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

  // Archive product
  Future<bool> archiveProduct(int productId) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _productService.archiveProduct(productId);
      
      if (result.success) {
        _setSuccessMessage(AppConstants.deleted);
        await loadProducts(); // Refresh the list
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

  // Restore product
  Future<bool> restoreProduct(int productId) async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final result = await _productService.restoreProduct(productId);
      
      if (result.success) {
        _setSuccessMessage('Icyicuruzwa cyasubijwe neza!');
        await loadProducts(); // Refresh the list
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

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(ProductCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _applyFilters();
  }

  // Get product by ID
  Product? getProductById(int productId) {
    try {
      return _products.firstWhere((product) => product.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(ProductCategory category) {
    return _groupedProducts[category] ?? [];
  }

  // Get low stock products
  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }

  // Get out of stock products
  List<Product> get outOfStockProducts {
    return _products.where((product) => product.isOutOfStock).toList();
  }

  // Get critical stock products
  List<Product> get criticalStockProducts {
    return _products.where((product) => product.isCriticalStock).toList();
  }

  // Get product statistics
  Future<ProductStats> getProductStats() async {
    try {
      return await _productService.getProductStats();
    } catch (e) {
      _setError('Habayeho ikosa mu gushaka imibare: ${e.toString()}');
      return ProductStats(
        totalProducts: 0,
        inStockProducts: 0,
        lowStockProducts: 0,
        outOfStockProducts: 0,
        totalStockValue: 0.0,
        categoryCount: {},
        categoryValue: {},
      );
    }
  }

  // Validate product
  Future<bool> validateProduct({
    required String productName,
    required ProductCategory category,
    required double unitPrice,
    required int currentStock,
    required int minStockLevel,
    int? excludeProductId,
  }) async {
    try {
      final result = await _productService.validateProduct(
        productName: productName,
        category: category,
        unitPrice: unitPrice,
        currentStock: currentStock,
        minStockLevel: minStockLevel,
        excludeProductId: excludeProductId,
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

  // Initialize default products
  Future<void> initializeDefaultProducts() async {
    try {
      await _productService.initializeDefaultProducts();
      await loadProducts();
    } catch (e) {
      _setError('Habayeho ikosa mu gushiraho ibicuruzwa: ${e.toString()}');
    }
  }

  // Private helper methods
  Future<void> _updateGroupedProducts() async {
    _groupedProducts = await _productService.getProductsGroupedByCategory();
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.productName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    // Sort by name
    filtered.sort((a, b) => a.productName.compareTo(b.productName));
    
    _filteredProducts = filtered;
    notifyListeners();
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

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear messages manually
  void clearMessages() {
    _clearMessages();
  }

  void clearError() {
    _clearError();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  // Get summary statistics
  Map<String, dynamic> get summary {
    final totalProducts = _products.length;
    final inStockProducts = _products.where((p) => p.currentStock > 0).length;
    final lowStockProducts = _products.where((p) => p.isLowStock).length;
    final outOfStockProducts = _products.where((p) => p.isOutOfStock).length;
    final totalStockValue = _products.fold(0.0, (sum, p) => sum + p.totalValue);
    
    return {
      'totalProducts': totalProducts,
      'inStockProducts': inStockProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'totalStockValue': totalStockValue,
    };
  }

  // Get category counts
  Map<ProductCategory, int> get categoryCounts {
    final Map<ProductCategory, int> counts = {};
    for (final product in _products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }
    return counts;
  }

  // Check if product name exists
  bool productNameExists(String name, {int? excludeId}) {
    return _products.any((product) =>
        product.productName.toLowerCase() == name.toLowerCase() &&
        product.productId != excludeId);
  }

  // Get products for dropdown
  List<Product> get activeProducts {
    return _products.where((product) => product.isActive).toList();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }
}
