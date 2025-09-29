import 'package:sqflite/sqflite.dart';
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:connectivity_plus/connectivity_plus.dart';
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
    _localDatabase ??= await DatabaseConfig.initializeLocalDatabase();
    return _localDatabase!;
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
      print('Failed to connect to remote database: $e');
      return null;
    }
  }

  // Check internet connectivity
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Close connections
  Future<void> closeConnections() async {
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
    final db = await localDatabase;
    final maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
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
    final maps = await db.query('users', where: 'is_active = 1');
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

  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    final db = await localDatabase;
    final whereClause = activeOnly ? 'is_active = 1' : null;
    final maps = await db.query(
      'products',
      where: whereClause,
      orderBy: 'category, product_name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
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

  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    final db = await localDatabase;
    final maps = await db.query(
      'products',
      where: 'category = ? AND is_active = 1',
      whereArgs: [category.toString().split('.').last],
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
      
      // Update product stock
      final product = await getProductById(movement.productId);
      if (product != null) {
        int newStock = product.currentStock;
        
        if (movement.movementType.increasesStock) {
          newStock += movement.quantity;
        } else if (movement.movementType.decreasesStock) {
          newStock -= movement.quantity;
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
  }) async {
    final db = await localDatabase;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND movement_date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    
    if (endDate != null) {
      whereClause += ' AND movement_date < ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }
    
    if (productId != null) {
      whereClause += ' AND product_id = ?';
      whereArgs.add(productId);
    }
    
    if (movementType != null) {
      whereClause += ' AND movement_type = ?';
      whereArgs.add(movementType.toString().split('.').last);
    }
    
    final maps = await db.query(
      'stock_movements',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'movement_date DESC, movement_time DESC',
    );
    
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getTodayStockMovements() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getStockMovements(startDate: startOfDay, endDate: endOfDay);
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await localDatabase;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Total items in stock
    final stockResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(current_stock * unit_price) as value FROM products WHERE is_active = 1 AND current_stock > 0'
    );
    
    // Today's sales
    final salesResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(total_amount) as amount FROM stock_movements WHERE movement_type = "BYAGURISHIJWE" AND movement_date = ?',
      [today]
    );
    
    // Today's damaged items
    final damagedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stock_movements WHERE movement_type = "BYONGEWE" AND movement_date = ?',
      [today]
    );
    
    // Low stock products
    final lowStockResult = await db.rawQuery(
      'SELECT * FROM products WHERE is_active = 1 AND current_stock <= min_stock_level ORDER BY current_stock ASC'
    );
    
    return {
      'itemsInStock': stockResult.first['count'] ?? 0,
      'stockValue': stockResult.first['value'] ?? 0.0,
      'todaySalesCount': salesResult.first['count'] ?? 0,
      'todaySalesAmount': salesResult.first['amount'] ?? 0.0,
      'todayDamagedCount': damagedResult.first['count'] ?? 0,
      'lowStockProducts': lowStockResult.map((map) => Product.fromMap(map)).toList(),
    };
  }

  // Initialize default products
  Future<void> initializeDefaultProducts() async {
    final db = await localDatabase;
    
    // Check if products already exist
    final existingProducts = await db.query('products', limit: 1);
    if (existingProducts.isNotEmpty) {
      return; // Products already initialized
    }
    
    // Insert default products from constants
    for (final productData in AppConstants.defaultProducts) {
      final product = Product(
        productName: productData['name'],
        category: ProductCategory.values.firstWhere(
          (e) => e.toString().split('.').last == productData['category'],
        ),
        unitPrice: productData['price'],
        currentStock: productData['stock'],
        syncStatus: 1, // Mark as synced since these are initial data
      );
      
      await db.insert('products', product.toMap());
    }
  }

  // Sync queue operations
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

  // Backup and restore
  Future<Map<String, dynamic>> exportData() async {
    final db = await localDatabase;
    
    final users = await db.query('users');
    final products = await db.query('products');
    final stockMovements = await db.query('stock_movements');
    final dailySummaries = await db.query('daily_summaries');
    final productSnapshots = await db.query('product_daily_snapshots');
    
    return {
      'users': users,
      'products': products,
      'stock_movements': stockMovements,
      'daily_summaries': dailySummaries,
      'product_daily_snapshots': productSnapshots,
      'export_date': DateTime.now().toIso8601String(),
      'version': AppConfig.appVersion,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await localDatabase;
    
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('users');
      await txn.delete('products');
      await txn.delete('stock_movements');
      await txn.delete('daily_summaries');
      await txn.delete('product_daily_snapshots');
      
      // Import data
      for (final user in data['users'] ?? []) {
        await txn.insert('users', user);
      }
      
      for (final product in data['products'] ?? []) {
        await txn.insert('products', product);
      }
      
      for (final movement in data['stock_movements'] ?? []) {
        await txn.insert('stock_movements', movement);
      }
      
      for (final summary in data['daily_summaries'] ?? []) {
        await txn.insert('daily_summaries', summary);
      }
      
      for (final snapshot in data['product_daily_snapshots'] ?? []) {
        await txn.insert('product_daily_snapshots', snapshot);
      }
    });
  }
}
