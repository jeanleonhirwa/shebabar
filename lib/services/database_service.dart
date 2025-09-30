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

  // OFFLINE SYNC FUNCTIONALITY

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Get all pending sync items (items with sync_status = 0)
  Future<Map<String, List<Map<String, dynamic>>>> getPendingSyncData() async {
    final db = await localDatabase;
    
    final pendingUsers = await db.query(
      'users',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
    
    final pendingProducts = await db.query(
      'products',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
    
    final pendingMovements = await db.query(
      'stock_movements',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
    
    final pendingSummaries = await db.query(
      'daily_summaries',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return {
      'users': pendingUsers,
      'products': pendingProducts,
      'stock_movements': pendingMovements,
      'daily_summaries': pendingSummaries,
    };
  }

  // Sync pending data to remote server
  Future<bool> syncToRemote() async {
    try {
      if (!await isOnline()) {
        return false;
      }

      final pendingData = await getPendingSyncData();
      final remote = await remoteConnection;
      
      if (remote == null) {
        return false;
      }

      // Sync users
      for (final user in pendingData['users']!) {
        await remote.query('''
          INSERT INTO users (username, password_hash, full_name, role, is_active, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
          password_hash = VALUES(password_hash),
          full_name = VALUES(full_name),
          role = VALUES(role),
          is_active = VALUES(is_active),
          updated_at = VALUES(updated_at)
        ''', [
          user['username'],
          user['password_hash'],
          user['full_name'],
          user['role'],
          user['is_active'],
          user['created_at'],
          user['updated_at'],
        ]);
      }

      // Sync products
      for (final product in pendingData['products']!) {
        await remote.query('''
          INSERT INTO products (product_name, category, unit_price, current_stock, min_stock_level, is_active, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
          product_name = VALUES(product_name),
          category = VALUES(category),
          unit_price = VALUES(unit_price),
          current_stock = VALUES(current_stock),
          min_stock_level = VALUES(min_stock_level),
          is_active = VALUES(is_active),
          updated_at = VALUES(updated_at)
        ''', [
          product['product_name'],
          product['category'],
          product['unit_price'],
          product['current_stock'],
          product['min_stock_level'],
          product['is_active'],
          product['created_at'],
          product['updated_at'],
        ]);
      }

      // Sync stock movements
      for (final movement in pendingData['stock_movements']!) {
        await remote.query('''
          INSERT INTO stock_movements (product_id, movement_type, quantity, unit_price, total_amount, notes, movement_time, created_by)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          movement['product_id'],
          movement['movement_type'],
          movement['quantity'],
          movement['unit_price'],
          movement['total_amount'],
          movement['notes'],
          movement['movement_time'],
          movement['created_by'],
        ]);
      }

      // Sync daily summaries
      for (final summary in pendingData['daily_summaries']!) {
        await remote.query('''
          INSERT INTO daily_summaries (summary_date, total_sales, total_quantity_sold, total_incoming, total_damaged, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
          total_sales = VALUES(total_sales),
          total_quantity_sold = VALUES(total_quantity_sold),
          total_incoming = VALUES(total_incoming),
          total_damaged = VALUES(total_damaged),
          updated_at = VALUES(updated_at)
        ''', [
          summary['summary_date'],
          summary['total_sales'],
          summary['total_quantity_sold'],
          summary['total_incoming'],
          summary['total_damaged'],
          summary['created_at'],
          summary['updated_at'],
        ]);
      }

      // Mark all synced items as synced (sync_status = 1)
      await _markAsSynced();
      
      return true;
    } catch (e) {
      print('Sync to remote failed: $e');
      return false;
    }
  }

  // Sync data from remote server to local
  Future<bool> syncFromRemote() async {
    try {
      if (!await isOnline()) {
        return false;
      }

      final remote = await remoteConnection;
      if (remote == null) {
        return false;
      }

      final db = await localDatabase;

      // Get last sync timestamp
      final lastSync = await _getLastSyncTimestamp();

      // Sync users
      final remoteUsers = await remote.query('''
        SELECT * FROM users WHERE updated_at > ?
      ''', [lastSync]);

      for (final user in remoteUsers) {
        await db.insert(
          'users',
          {
            'username': user['username'],
            'password_hash': user['password_hash'],
            'full_name': user['full_name'],
            'role': user['role'],
            'is_active': user['is_active'] ? 1 : 0,
            'created_at': user['created_at'].toString(),
            'updated_at': user['updated_at'].toString(),
            'sync_status': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Sync products
      final remoteProducts = await remote.query('''
        SELECT * FROM products WHERE updated_at > ?
      ''', [lastSync]);

      for (final product in remoteProducts) {
        await db.insert(
          'products',
          {
            'product_id': product['product_id'],
            'product_name': product['product_name'],
            'category': product['category'],
            'unit_price': product['unit_price'],
            'current_stock': product['current_stock'],
            'min_stock_level': product['min_stock_level'],
            'is_active': product['is_active'] ? 1 : 0,
            'created_at': product['created_at'].toString(),
            'updated_at': product['updated_at'].toString(),
            'sync_status': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Sync stock movements
      final remoteMovements = await remote.query('''
        SELECT * FROM stock_movements WHERE movement_time > ?
      ''', [lastSync]);

      for (final movement in remoteMovements) {
        await db.insert(
          'stock_movements',
          {
            'movement_id': movement['movement_id'],
            'product_id': movement['product_id'],
            'movement_type': movement['movement_type'],
            'quantity': movement['quantity'],
            'unit_price': movement['unit_price'],
            'total_amount': movement['total_amount'],
            'notes': movement['notes'],
            'movement_time': movement['movement_time'].toString(),
            'created_by': movement['created_by'],
            'sync_status': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Update last sync timestamp
      await _updateLastSyncTimestamp();

      return true;
    } catch (e) {
      print('Sync from remote failed: $e');
      return false;
    }
  }

  // Perform full bidirectional sync
  Future<bool> performFullSync() async {
    try {
      if (!await isOnline()) {
        return false;
      }

      // First sync local changes to remote
      final uploadSuccess = await syncToRemote();
      if (!uploadSuccess) {
        return false;
      }

      // Then sync remote changes to local
      final downloadSuccess = await syncFromRemote();
      return downloadSuccess;
    } catch (e) {
      print('Full sync failed: $e');
      return false;
    }
  }

  // Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final db = await localDatabase;
    
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM users WHERE sync_status = 0) +
        (SELECT COUNT(*) FROM products WHERE sync_status = 0) +
        (SELECT COUNT(*) FROM stock_movements WHERE sync_status = 0) +
        (SELECT COUNT(*) FROM daily_summaries WHERE sync_status = 0) as total_pending
    ''');
    
    return result.first['total_pending'] as int? ?? 0;
  }

  // Mark all pending items as synced
  Future<void> _markAsSynced() async {
    final db = await localDatabase;
    
    await db.transaction((txn) async {
      await txn.update('users', {'sync_status': 1}, where: 'sync_status = 0');
      await txn.update('products', {'sync_status': 1}, where: 'sync_status = 0');
      await txn.update('stock_movements', {'sync_status': 1}, where: 'sync_status = 0');
      await txn.update('daily_summaries', {'sync_status': 1}, where: 'sync_status = 0');
    });
  }

  // Get last sync timestamp
  Future<String> _getLastSyncTimestamp() async {
    final db = await localDatabase;
    
    try {
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['last_sync_timestamp'],
      );
      
      if (result.isNotEmpty) {
        return result.first['value'] as String;
      }
    } catch (e) {
      // Table might not exist, create it
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    
    // Return a timestamp from 30 days ago as default
    final defaultTimestamp = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    
    return defaultTimestamp;
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final db = await localDatabase;
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'app_settings',
      {
        'key': 'last_sync_timestamp',
        'value': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Force mark item as needing sync (useful for conflict resolution)
  Future<void> markForSync(String table, Map<String, dynamic> where) async {
    final db = await localDatabase;
    await db.update(
      table,
      {'sync_status': 0},
      where: where.keys.map((key) => '$key = ?').join(' AND '),
      whereArgs: where.values.toList(),
    );
  }

  // Get sync status summary
  Future<Map<String, dynamic>> getSyncStatus() async {
    final db = await localDatabase;
    final isConnected = await isOnline();
    final pendingCount = await getPendingSyncCount();
    
    final lastSyncResult = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
    );
    
    String? lastSyncTime;
    if (lastSyncResult.isNotEmpty) {
      lastSyncTime = lastSyncResult.first['value'] as String?;
    }
    
    return {
      'isOnline': isConnected,
      'pendingCount': pendingCount,
      'lastSyncTime': lastSyncTime,
      'needsSync': pendingCount > 0,
    };
  }
}
