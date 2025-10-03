import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import '../models/product.dart';
import '../models/stock_movement.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _stockMovementsCollection => _firestore.collection('stock_movements');
  CollectionReference get _dailySummariesCollection => _firestore.collection('daily_summaries');

  // Current user
  User? get currentFirebaseUser => _auth.currentUser;

  // Initialize Firebase (call this in main.dart)
  Future<void> initialize() async {
    // Firebase is initialized in main.dart with Firebase.initializeApp()
    if (kDebugMode) {
      print('Firebase service initialized');
    }
  }

  // ==================== AUTH OPERATIONS ====================
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Create user error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== USER OPERATIONS ====================

  // Create user profile in Firestore
  Future<void> createUserProfile(app_user.User user) async {
    try {
      await _usersCollection.doc(user.userId.toString()).set(user.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Create user profile error: $e');
      }
      rethrow;
    }
  }

  // Get user profile by ID
  Future<app_user.User?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return app_user.User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get user profile error: $e');
      }
      return null;
    }
  }

  // Get user by username
  Future<app_user.User?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return app_user.User.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get user by username error: $e');
      }
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(app_user.User user) async {
    try {
      await _usersCollection.doc(user.userId.toString()).update(user.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Update user profile error: $e');
      }
      rethrow;
    }
  }

  // Get all users
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.orderBy('full_name').get();
      return querySnapshot.docs
          .map((doc) => app_user.User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Get all users error: $e');
      }
      return [];
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  // Add product
  Future<String> addProduct(Product product) async {
    try {
      final docRef = await _productsCollection.add(product.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Add product error: $e');
      }
      rethrow;
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['product_id'] = doc.id; // Add document ID
        return Product.fromMap(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get product by ID error: $e');
      }
      return null;
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    try {
      Query query = _productsCollection.orderBy('product_name');
      
      if (activeOnly) {
        query = query.where('is_active', isEqualTo: true);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['product_id'] = doc.id; // Add document ID
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Get all products error: $e');
      }
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    try {
      final categoryString = category.toString().split('.').last;
      final querySnapshot = await _productsCollection
          .where('category', isEqualTo: categoryString)
          .where('is_active', isEqualTo: true)
          .orderBy('product_name')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['product_id'] = doc.id; // Add document ID
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Get products by category error: $e');
      }
      return [];
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Firestore doesn't support full-text search, so we'll use array-contains for now
      // For better search, consider using Algolia or similar service
      final querySnapshot = await _productsCollection
          .where('is_active', isEqualTo: true)
          .orderBy('product_name')
          .get();
      
      // Filter results on client side
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['product_id'] = doc.id;
            return Product.fromMap(data);
          })
          .where((product) => 
              product.productName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Search products error: $e');
      }
      return [];
    }
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.productId.toString()).update(product.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Update product error: $e');
      }
      rethrow;
    }
  }

  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _productsCollection.doc(productId).update({
        'current_stock': newStock,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Update product stock error: $e');
      }
      rethrow;
    }
  }

  // ==================== STOCK MOVEMENT OPERATIONS ====================

  // Add stock movement
  Future<String> addStockMovement(StockMovement movement) async {
    try {
      // Use Firestore transaction to ensure data consistency
      return await _firestore.runTransaction<String>((transaction) async {
        // Add stock movement
        final movementRef = _stockMovementsCollection.doc();
        transaction.set(movementRef, movement.toMap());
        
        // Update product stock
        final productRef = _productsCollection.doc(movement.productId.toString());
        final productDoc = await transaction.get(productRef);
        
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          int currentStock = productData['current_stock'] ?? 0;
          
          // Calculate new stock based on movement type
          switch (movement.movementType) {
            case MovementType.BYINJIYE:
              currentStock += movement.quantity;
              break;
            case MovementType.BYAGURISHIJWE:
              currentStock -= movement.quantity;
              break;
            case MovementType.BYONGEWE:
              currentStock -= movement.quantity;
              break;
          }
          
          transaction.update(productRef, {
            'current_stock': currentStock,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        return movementRef.id;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Add stock movement error: $e');
      }
      rethrow;
    }
  }

  // Get stock movements with filters
  Future<List<StockMovement>> getStockMovements({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    MovementType? movementType,
    int limit = 100,
  }) async {
    try {
      Query query = _stockMovementsCollection
          .orderBy('movement_date', descending: true)
          .orderBy('movement_time', descending: true);
      
      if (startDate != null) {
        query = query.where('movement_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('movement_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      if (productId != null) {
        query = query.where('product_id', isEqualTo: productId);
      }
      
      if (movementType != null) {
        query = query.where('movement_type', isEqualTo: movementType.toString().split('.').last);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['movement_id'] = doc.id; // Add document ID
        return StockMovement.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Get stock movements error: $e');
      }
      return [];
    }
  }

  // Get today's stock movements
  Future<List<StockMovement>> getTodayStockMovements() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return await getStockMovements(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // ==================== DASHBOARD STATS ====================

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      // Get today's sales
      final salesQuery = await _stockMovementsCollection
          .where('movement_type', isEqualTo: 'BYAGURISHIJWE')
          .where('movement_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('movement_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      int todaySales = salesQuery.docs.length;
      double todayRevenue = salesQuery.docs.fold(0.0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['total_amount'] ?? 0.0);
      });
      
      // Get low stock products
      final lowStockQuery = await _productsCollection
          .where('is_active', isEqualTo: true)
          .get();
      
      int lowStockProducts = 0;
      int totalProducts = 0;
      
      for (final doc in lowStockQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalProducts++;
        final currentStock = data['current_stock'] ?? 0;
        final minStockLevel = data['min_stock_level'] ?? 5;
        if (currentStock <= minStockLevel) {
          lowStockProducts++;
        }
      }
      
      return {
        'todaySales': todaySales,
        'todayRevenue': todayRevenue,
        'lowStockProducts': lowStockProducts,
        'totalProducts': totalProducts,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Get dashboard stats error: $e');
      }
      return {
        'todaySales': 0,
        'todayRevenue': 0.0,
        'lowStockProducts': 0,
        'totalProducts': 0,
      };
    }
  }

  // ==================== UTILITY METHODS ====================

  // Initialize default products (call once during setup)
  Future<void> initializeDefaultProducts() async {
    try {
      // Check if products already exist
      final existingProducts = await _productsCollection.limit(1).get();
      if (existingProducts.docs.isNotEmpty) return;
      
      // Insert default products
      final defaultProducts = [
        Product(
          productName: 'Mutzig',
          category: ProductCategory.INZOGA_NINI,
          unitPrice: 800.0,
          currentStock: 50,
          minStockLevel: 10,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          productName: 'Primus',
          category: ProductCategory.INZOGA_NTO,
          unitPrice: 700.0,
          currentStock: 30,
          minStockLevel: 10,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          productName: 'Coca Cola',
          category: ProductCategory.IBINYOBWA_BIDAFITE_ALCOHOL,
          unitPrice: 400.0,
          currentStock: 100,
          minStockLevel: 20,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      for (final product in defaultProducts) {
        await addProduct(product);
      }
      
      if (kDebugMode) {
        print('Default products initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Initialize default products error: $e');
      }
    }
  }
}
