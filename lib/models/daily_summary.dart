class DailySummary {
  final int? summaryId;
  final DateTime summaryDate;
  final int totalSalesQuantity;
  final double totalSalesAmount;
  final int totalIncomingQuantity;
  final int totalDamagedQuantity;
  final double totalDamagedAmount;
  final double closingStockValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  DailySummary({
    this.summaryId,
    required this.summaryDate,
    this.totalSalesQuantity = 0,
    this.totalSalesAmount = 0.0,
    this.totalIncomingQuantity = 0,
    this.totalDamagedQuantity = 0,
    this.totalDamagedAmount = 0.0,
    this.closingStockValue = 0.0,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      summaryId: map['summary_id'],
      summaryDate: DateTime.parse(map['summary_date']),
      totalSalesQuantity: map['total_sales_quantity'] ?? 0,
      totalSalesAmount: (map['total_sales_amount'] as num?)?.toDouble() ?? 0.0,
      totalIncomingQuantity: map['total_incoming_quantity'] ?? 0,
      totalDamagedQuantity: map['total_damaged_quantity'] ?? 0,
      totalDamagedAmount: (map['total_damaged_amount'] as num?)?.toDouble() ?? 0.0,
      closingStockValue: (map['closing_stock_value'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary_id': summaryId,
      'summary_date': summaryDate.toIso8601String().split('T')[0],
      'total_sales_quantity': totalSalesQuantity,
      'total_sales_amount': totalSalesAmount,
      'total_incoming_quantity': totalIncomingQuantity,
      'total_damaged_quantity': totalDamagedQuantity,
      'total_damaged_amount': totalDamagedAmount,
      'closing_stock_value': closingStockValue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  DailySummary copyWith({
    int? summaryId,
    DateTime? summaryDate,
    int? totalSalesQuantity,
    double? totalSalesAmount,
    int? totalIncomingQuantity,
    int? totalDamagedQuantity,
    double? totalDamagedAmount,
    double? closingStockValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return DailySummary(
      summaryId: summaryId ?? this.summaryId,
      summaryDate: summaryDate ?? this.summaryDate,
      totalSalesQuantity: totalSalesQuantity ?? this.totalSalesQuantity,
      totalSalesAmount: totalSalesAmount ?? this.totalSalesAmount,
      totalIncomingQuantity: totalIncomingQuantity ?? this.totalIncomingQuantity,
      totalDamagedQuantity: totalDamagedQuantity ?? this.totalDamagedQuantity,
      totalDamagedAmount: totalDamagedAmount ?? this.totalDamagedAmount,
      closingStockValue: closingStockValue ?? this.closingStockValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  double get netProfit => totalSalesAmount - totalDamagedAmount;
  double get averageSaleValue => totalSalesQuantity > 0 
      ? totalSalesAmount / totalSalesQuantity 
      : 0.0;

  @override
  String toString() {
    return 'DailySummary{summaryId: $summaryId, date: $summaryDate, sales: $totalSalesAmount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummary &&
          runtimeType == other.runtimeType &&
          summaryId == other.summaryId &&
          summaryDate == other.summaryDate;

  @override
  int get hashCode => summaryId.hashCode ^ summaryDate.hashCode;
}

class ProductDailySnapshot {
  final int? snapshotId;
  final int productId;
  final DateTime snapshotDate;
  final int openingStock;
  final int incoming;
  final int sold;
  final int damaged;
  final int closingStock;
  final double unitPrice;
  final double totalValue;
  final DateTime? createdAt;
  final int syncStatus;

  ProductDailySnapshot({
    this.snapshotId,
    required this.productId,
    required this.snapshotDate,
    required this.openingStock,
    this.incoming = 0,
    this.sold = 0,
    this.damaged = 0,
    required this.closingStock,
    required this.unitPrice,
    required this.totalValue,
    this.createdAt,
    this.syncStatus = 0,
  });

  factory ProductDailySnapshot.fromMap(Map<String, dynamic> map) {
    return ProductDailySnapshot(
      snapshotId: map['snapshot_id'],
      productId: map['product_id'],
      snapshotDate: DateTime.parse(map['snapshot_date']),
      openingStock: map['opening_stock'],
      incoming: map['incoming'] ?? 0,
      sold: map['sold'] ?? 0,
      damaged: map['damaged'] ?? 0,
      closingStock: map['closing_stock'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalValue: (map['total_value'] as num).toDouble(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'snapshot_id': snapshotId,
      'product_id': productId,
      'snapshot_date': snapshotDate.toIso8601String().split('T')[0],
      'opening_stock': openingStock,
      'incoming': incoming,
      'sold': sold,
      'damaged': damaged,
      'closing_stock': closingStock,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'created_at': createdAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  ProductDailySnapshot copyWith({
    int? snapshotId,
    int? productId,
    DateTime? snapshotDate,
    int? openingStock,
    int? incoming,
    int? sold,
    int? damaged,
    int? closingStock,
    double? unitPrice,
    double? totalValue,
    DateTime? createdAt,
    int? syncStatus,
  }) {
    return ProductDailySnapshot(
      snapshotId: snapshotId ?? this.snapshotId,
      productId: productId ?? this.productId,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      openingStock: openingStock ?? this.openingStock,
      incoming: incoming ?? this.incoming,
      sold: sold ?? this.sold,
      damaged: damaged ?? this.damaged,
      closingStock: closingStock ?? this.closingStock,
      unitPrice: unitPrice ?? this.unitPrice,
      totalValue: totalValue ?? this.totalValue,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  int get totalMovement => incoming + sold + damaged;
  double get salesValue => sold * unitPrice;
  double get damagedValue => damaged * unitPrice;

  @override
  String toString() {
    return 'ProductDailySnapshot{snapshotId: $snapshotId, productId: $productId, date: $snapshotDate}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDailySnapshot &&
          runtimeType == other.runtimeType &&
          snapshotId == other.snapshotId;

  @override
  int get hashCode => snapshotId.hashCode;
}
