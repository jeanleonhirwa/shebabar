class Product {
  final String? productId;
  final String productName;
  final ProductCategory category;
  final double unitPrice;
  final int currentStock;
  final int minStockLevel;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    this.currentStock = 0,
    this.minStockLevel = 5,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['product_id'],
      productName: map['product_name'],
      category: ProductCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
      ),
      unitPrice: (map['unit_price'] as num).toDouble(),
      currentStock: map['current_stock'] ?? 0,
      minStockLevel: map['min_stock_level'] ?? 5,
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category.toString().split('.').last,
      'unit_price': unitPrice,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? productId,
    String? productName,
    ProductCategory? category,
    double? unitPrice,
    int? currentStock,
    int? minStockLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalValue => currentStock * unitPrice;

  bool get isLowStock => currentStock <= minStockLevel;
  bool get isCriticalStock => currentStock <= 2;
  bool get isOutOfStock => currentStock <= 0;

  @override
  String toString() {
    return 'Product{productId: $productId, productName: $productName, currentStock: $currentStock}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}

enum ProductCategory {
  INZOGA_NINI,      // Large beers
  INZOGA_NTO,       // Small beers
  IBINYOBWA_BIDAFITE_ALCOHOL,  // Soft drinks
  VINO,             // Wine
  SPIRITS,          // Spirits
  AMAZI,            // Water
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.INZOGA_NINI:
        return 'Inzoga Nini'; // Large Beer
      case ProductCategory.INZOGA_NTO:
        return 'Inzoga Nto'; // Small Beer
      case ProductCategory.IBINYOBWA_BIDAFITE_ALCOHOL:
        return 'Ibinyobwa bidafite Alcohol'; // Soft Drinks
      case ProductCategory.VINO:
        return 'Vino'; // Wine
      case ProductCategory.SPIRITS:
        return 'Spirits'; // Spirits
      case ProductCategory.AMAZI:
        return 'Amazi'; // Water
    }
  }

  String get icon {
    switch (this) {
      case ProductCategory.INZOGA_NINI:
        return '🍺';
      case ProductCategory.INZOGA_NTO:
        return '🍻';
      case ProductCategory.IBINYOBWA_BIDAFITE_ALCOHOL:
        return '🥤';
      case ProductCategory.VINO:
        return '🍷';
      case ProductCategory.SPIRITS:
        return '🥃';
      case ProductCategory.AMAZI:
        return '💧';
    }
  }
}
