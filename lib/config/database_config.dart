import 'package:mysql1/mysql1.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_config.dart';

class DatabaseConfig {
  // MySQL Connection Settings
  static ConnectionSettings get mysqlSettings => ConnectionSettings(
    host: AppConfig.dbHost,
    port: AppConfig.dbPort,
    user: AppConfig.dbUser,
    password: AppConfig.dbPassword,
    db: AppConfig.dbName,
  );

  // Local SQLite Database Schema
  static const String createUsersTable = '''
    CREATE TABLE users (
      user_id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      full_name TEXT NOT NULL,
      role TEXT NOT NULL CHECK (role IN ('owner', 'employee')),
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      last_login TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''';

  static const String createProductsTable = '''
    CREATE TABLE products (
      product_id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_name TEXT NOT NULL,
      category TEXT NOT NULL,
      unit_price REAL NOT NULL,
      current_stock INTEGER DEFAULT 0,
      min_stock_level INTEGER DEFAULT 5,
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      sync_status INTEGER DEFAULT 0
    )
  ''';

  static const String createStockMovementsTable = '''
    CREATE TABLE stock_movements (
      movement_id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      movement_type TEXT NOT NULL CHECK (movement_type IN ('BYINJIYE', 'BYAGURISHIJWE', 'BYONGEWE')),
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      total_amount REAL NOT NULL,
      notes TEXT,
      user_id INTEGER NOT NULL,
      movement_date TEXT NOT NULL,
      movement_time TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      sync_status INTEGER DEFAULT 0,
      FOREIGN KEY (product_id) REFERENCES products(product_id),
      FOREIGN KEY (user_id) REFERENCES users(user_id)
    )
  ''';

  static const String createDailySummariesTable = '''
    CREATE TABLE daily_summaries (
      summary_id INTEGER PRIMARY KEY AUTOINCREMENT,
      summary_date TEXT UNIQUE NOT NULL,
      total_sales_quantity INTEGER DEFAULT 0,
      total_sales_amount REAL DEFAULT 0,
      total_incoming_quantity INTEGER DEFAULT 0,
      total_damaged_quantity INTEGER DEFAULT 0,
      total_damaged_amount REAL DEFAULT 0,
      closing_stock_value REAL DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      sync_status INTEGER DEFAULT 0
    )
  ''';

  static const String createProductDailySnapshotsTable = '''
    CREATE TABLE product_daily_snapshots (
      snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      snapshot_date TEXT NOT NULL,
      opening_stock INTEGER NOT NULL,
      incoming INTEGER DEFAULT 0,
      sold INTEGER DEFAULT 0,
      damaged INTEGER DEFAULT 0,
      closing_stock INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      total_value REAL NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      sync_status INTEGER DEFAULT 0,
      UNIQUE (product_id, snapshot_date),
      FOREIGN KEY (product_id) REFERENCES products(product_id)
    )
  ''';

  // Sync queue table for offline operations
  static const String createSyncQueueTable = '''
    CREATE TABLE sync_queue (
      queue_id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL,
      operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
      record_id INTEGER NOT NULL,
      data TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      retry_count INTEGER DEFAULT 0,
      status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'synced', 'failed'))
    )
  ''';

  static List<String> get createTableStatements => [
    createUsersTable,
    createProductsTable,
    createStockMovementsTable,
    createDailySummariesTable,
    createProductDailySnapshotsTable,
    createSyncQueueTable,
  ];

  // Database initialization
  static Future<Database> initializeLocalDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConfig.localDbName);

    return await openDatabase(
      path,
      version: AppConfig.localDbVersion,
      onCreate: (db, version) async {
        for (String statement in createTableStatements) {
          await db.execute(statement);
        }
        
        // Insert default admin user
        await db.execute('''
          INSERT INTO users (username, password_hash, full_name, role, sync_status) 
          VALUES ('mama', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ORmCvKlFZBfi', 'Mama (Owner)', 'owner', 1)
        ''');
      },
    );
  }
}
