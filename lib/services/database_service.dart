import 'package:sqflite/sqflite.dart';
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../config/database_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/daily_summary.dart';

class DatabaseService {
  static Database? _localDatabase;
  static mysql.MySqlConnection? _remoteConnection;
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Initialize local database
  Future<Database> get localDatabase async {
    if (_localDatabase == null) {
      try {
        _localDatabase = await DatabaseConfig.initializeLocalDatabase();
      } catch (e) {
        print('Local database initialization failed: $e');
        // Fallback to in-memory database
        _localDatabase = await _initializeWebDatabase();
      }
    }
    return _localDatabase!;
  }

  // Initialize web-compatible in-memory database
  Future<Database> _initializeWebDatabase() async {
    return await openDatabase(
      ':memory:',
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        for (String statement in DatabaseConfig.createTableStatements) {
          await db.execute(statement);
        }
        
        // Insert default admin user with correct password hash (admin123)
        await db.execute('''
          INSERT INTO users (username, password_hash, full_name, role, sync_status) 
          VALUES ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Administrator', 'owner', 1)
        ''');
      },
    );
  }

  // Initialize remote MySQL connection
  Future<mysql.MySqlConnection?> get remoteConnection async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return null;
      }

      _remoteConnection ??= await mysql.MySqlConnection.connect(
        DatabaseConfig.mysqlSettings,
      );
      return _remoteConnection;
    } catch (e) {
      print('MySQL connection failed: $e');
      return null;
    }
  }

  // Close connections
  Future<void> close() async {
    await _localDatabase?.close();
    await _remoteConnection?.close();
    _localDatabase = null;
    _remoteConnection = null;
  }

  // CRUD Operations for Users
  Future<int> insertUser(User user) async {
    final db = await localDatabase;
    final id = await db.insert('users', user.toMap());
    
    // Add to sync queue
    await _addToSyncQueue('users', 'INSERT', id, user.toMap());
    
    return id;
  }

  Future<User?> getUserByUsername(String username) async {
    // Try MySQL first, then fallback to local database
    try {
      final connection = await remoteConnection;
      if (connection != null) {
        final results = await connection.query(
          'SELECT * FROM users WHERE username = ? AND is_active = 1 LIMIT 1',
          [username],
        );
        
        if (results.isNotEmpty) {
          final row = results.first;
          return User(
            userId: row['user_id'],
            username: row['username'],
            passwordHash: row['password_hash'],
            fullName: row['full_name'],
            role: UserRole.values.firstWhere((e) => e.toString().split('.').last == row['role']),
            isActive: row['is_active'] == 1,
            createdAt: DateTime.parse(row['created_at'].toString()),
            lastLogin: row['last_login'] != null ? DateTime.parse(row['last_login'].toString()) : null,
          );
        }
      }
    } catch (e) {
      print('MySQL query failed, using local database: $e');
    }
    
    // Fallback to local database
    final db = await localDatabase;
    final maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int userId) async {
    final db = await localDatabase;
    final maps = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await localDatabase;
    final maps = await db.query('users', orderBy: 'full_name');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await localDatabase;
    final count = await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
    
    // Add to sync queue
    await _addToSyncQueue('users', 'UPDATE', user.userId!, user.toMap());
    
    return count;
  }

  // CRUD Operations for Products
  Future<int> insertProduct(Product product) async {
    final db = await localDatabase;
    final id = await db.insert('products', product.toMap());
    
    // Add to sync queue
    await _addToSyncQueue('products', 'INSERT', id, product.toMap());
    
    return id;
  }

  Future<Product?> getProductById(int productId) async {
    final db = await localDatabase;
    final maps = await db.query(
      'products',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await localDatabase;
    final maps = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'product_name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await localDatabase;
    final maps = await db.query(
      'products',
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'product_name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await localDatabase;
    final maps = await db.query(
      'products',
      where: 'product_name LIKE ? AND is_active = 1',
      whereArgs: ['%$query%'],
      orderBy: 'product_name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await localDatabase;
    final count = await db.update(
      'products',
      product.toMap(),
      where: 'product_id = ?',
      whereArgs: [product.productId],
    );
    
    // Add to sync queue
    await _addToSyncQueue('products', 'UPDATE', product.productId!, product.toMap());
    
    return count;
  }

  Future<int> updateProductStock(int productId, int newStock) async {
    final db = await localDatabase;
    final count = await db.update(
      'products',
      {
        'current_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    
    // Add to sync queue
    await _addToSyncQueue('products', 'UPDATE', productId, {
      'current_stock': newStock,
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    return count;
  }

  // CRUD Operations for Stock Movements
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await localDatabase;
    
    // Start transaction to update both stock movement and product stock
    return await db.transaction((txn) async {
      // Insert stock movement
      final id = await txn.insert('stock_movements', movement.toMap());
      
      // Update product stock based on movement type
      final product = await getProductById(movement.productId);
      if (product != null) {
        int newStock = product.currentStock;
        
        switch (movement.movementType) {
          case MovementType.BYINJIYE:
            newStock += movement.quantity;
            break;
          case MovementType.BYAGURISHIJWE:
            newStock -= movement.quantity;
            break;
          case MovementType.BYONGEWE:
            newStock -= movement.quantity;
            break;
        }
        
        await txn.update(
          'products',
          {
            'current_stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
            'sync_status': 0,
          },
          where: 'product_id = ?',
          whereArgs: [movement.productId],
        );
      }
      
      // Add to sync queue
      await _addToSyncQueue('stock_movements', 'INSERT', id, movement.toMap());
      
      return id;
    });
  }

  Future<List<StockMovement>> getStockMovements({
    DateTime? startDate,
    DateTime? endDate,
    int? productId,
    MovementType? movementType,
    int limit = 100,
  }) async {
    final db = await localDatabase;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND movement_date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    
    if (endDate != null) {
      whereClause += ' AND movement_date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }
    
    if (productId != null) {
      whereClause += ' AND product_id = ?';
      whereArgs.add(productId);
    }
    
    if (movementType != null) {
      whereClause += ' AND movement_type = ?';
      whereArgs.add(movementType.toString().split('.').last.toUpperCase());
    }
    
    final maps = await db.query(
      'stock_movements',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'movement_date DESC, movement_time DESC',
      limit: limit,
    );
    
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getTodayStockMovements() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getStockMovements(
      startDate: DateTime.parse(today),
      endDate: DateTime.parse(today),
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await localDatabase;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Get today's sales
    final salesResult = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(total_amount), 0) as total
      FROM stock_movements 
      WHERE movement_type = 'BYAGURISHIJWE' AND movement_date = ?
    ''', [today]);
    
    // Get low stock products
    final lowStockResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM products 
      WHERE current_stock <= min_stock_level AND is_active = 1
    ''');
    
    // Get total products
    final productsResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM products 
      WHERE is_active = 1
    ''');
    
    return {
      'todaySales': salesResult.first['count'] ?? 0,
      'todayRevenue': salesResult.first['total'] ?? 0.0,
      'lowStockProducts': lowStockResult.first['count'] ?? 0,
      'totalProducts': productsResult.first['count'] ?? 0,
    };
  }

  // Sync operations
  Future<void> _addToSyncQueue(String tableName, String operation, int recordId, Map<String, dynamic> data) async {
    final db = await localDatabase;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await localDatabase;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  // Alias for sync provider compatibility
  Future<List<Map<String, dynamic>>> getPendingSyncData() async {
    return await getPendingSyncItems();
  }

  Future<void> markSyncItemCompleted(int queueId) async {
    final db = await localDatabase;
    await db.update(
      'sync_queue',
      {'status': 'synced'},
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  Future<void> markSyncItemFailed(int queueId) async {
    final db = await localDatabase;
    await db.update(
      'sync_queue',
      {
        'status': 'failed',
        'retry_count': 'retry_count + 1',
      },
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  Future<bool> performFullSync() async {
    try {
      final connection = await remoteConnection;
      if (connection == null) return false;

      final pendingItems = await getPendingSyncItems();
      
      for (final item in pendingItems) {
        try {
          // Perform sync operation based on table and operation
          // This is a simplified version - you'd implement full sync logic here
          await markSyncItemCompleted(item['queue_id']);
        } catch (e) {
          await markSyncItemFailed(item['queue_id']);
        }
      }
      
      return true;
    } catch (e) {
      print('Full sync failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    final db = await localDatabase;
    
    final pendingResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending'
    ''');
    
    final failedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue WHERE status = 'failed'
    ''');
    
    return {
      'pendingItems': pendingResult.first['count'] ?? 0,
      'failedItems': failedResult.first['count'] ?? 0,
      'lastSync': DateTime.now().toIso8601String(),
    };
  }

  Future<void> markForSync(String tableName, int recordId) async {
    final db = await localDatabase;
    await db.update(
      tableName,
      {'sync_status': 0},
      where: '${tableName.substring(0, tableName.length - 1)}_id = ?',
      whereArgs: [recordId],
    );
  }

  // Initialize default products
  Future<void> initializeDefaultProducts() async {
    final db = await localDatabase;
    
    // Check if products already exist
    final existingProducts = await db.query('products', limit: 1);
    if (existingProducts.isNotEmpty) return;
    
    // Insert default products
    final defaultProducts = [
      {
        'product_name': 'Mutzig',
        'category': 'INZOGA_NINI',
        'unit_price': 800.0,
        'current_stock': 50,
        'min_stock_level': 10,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      },
      {
        'product_name': 'Primus',
        'category': 'INZOGA_NTO',
        'unit_price': 700.0,
        'current_stock': 30,
        'min_stock_level': 10,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      },
      {
        'product_name': 'Coca Cola',
        'category': 'IBINYOBWA_BIDAFITE_ALCOHOL',
        'unit_price': 400.0,
        'current_stock': 100,
        'min_stock_level': 20,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      },
    ];
    
    for (final product in defaultProducts) {
      await db.insert('products', product);
    }
  }
}
