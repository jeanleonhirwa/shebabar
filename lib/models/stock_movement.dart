class StockMovement {
  final String? movementId;
  final String productId;
  final MovementType movementType;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? notes;
  final String userId;
  final DateTime movementDate;
  final DateTime movementTime;
  final DateTime? createdAt;

  StockMovement({
    this.movementId,
    required this.productId,
    required this.movementType,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.notes,
    required this.userId,
    required this.movementDate,
    required this.movementTime,
    this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      movementId: map['movement_id'],
      productId: map['product_id'],
      movementType: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['movement_type'],
      ),
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'],
      userId: map['user_id'],
      movementDate: DateTime.parse(map['movement_date']),
      movementTime: DateTime.parse(map['movement_time']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movement_id': movementId,
      'product_id': productId,
      'movement_type': movementType.toString().split('.').last,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'notes': notes,
      'user_id': userId,
      'movement_date': movementDate.toIso8601String().split('T')[0],
      'movement_time': movementTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StockMovement copyWith({
    String? movementId,
    String? productId,
    MovementType? movementType,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    String? notes,
    String? userId,
    DateTime? movementDate,
    DateTime? movementTime,
    DateTime? createdAt,
  }) {
    return StockMovement(
      movementId: movementId ?? this.movementId,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      movementDate: movementDate ?? this.movementDate,
      movementTime: movementTime ?? this.movementTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'StockMovement{movementId: $movementId, productId: $productId, type: $movementType, quantity: $quantity}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          movementId == other.movementId;

  @override
  int get hashCode => movementId.hashCode;
}

enum MovementType {
  BYINJIYE,      // Incoming/Received
  BYAGURISHIJWE, // Sold/Out
  BYONGEWE,      // Damaged/Spoiled
}

extension MovementTypeExtension on MovementType {
  String get displayName {
    switch (this) {
      case MovementType.BYINJIYE:
        return 'Byinjiye'; // Incoming
      case MovementType.BYAGURISHIJWE:
        return 'Byagurishijwe'; // Sold
      case MovementType.BYONGEWE:
        return 'Byongewe'; // Damaged
    }
  }

  String get icon {
    switch (this) {
      case MovementType.BYINJIYE:
        return '📦'; // Incoming
      case MovementType.BYAGURISHIJWE:
        return '💰'; // Sold
      case MovementType.BYONGEWE:
        return '❌'; // Damaged
    }
  }

  bool get increasesStock => this == MovementType.BYINJIYE;
  bool get decreasesStock => 
      this == MovementType.BYAGURISHIJWE || this == MovementType.BYONGEWE;
}
