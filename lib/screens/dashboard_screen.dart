import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/stock_movement.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/stock_status_indicator.dart';
import 'stock_management_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeProviders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    await Future.wait([
      stockProvider.initialize(),
      productProvider.initialize(),
    ]);
  }

  void _startAutoRefresh() {
    // Auto-refresh dashboard every 30 seconds
    Future.delayed(const Duration(seconds: AppConfig.dashboardRefreshSeconds), () {
      if (mounted && _currentIndex == 0) {
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        stockProvider.refreshData();
        _startAutoRefresh();
      }
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildDashboardPage(),
          const StockManagementScreen(),
          const ProductsScreen(),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboardPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final stockProvider = Provider.of<StockProvider>(context, listen: false);
              stockProvider.refreshData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final stockProvider = Provider.of<StockProvider>(context, listen: false);
          await stockProvider.refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConfig.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Welcome
              _buildHeader(),
              const SizedBox(height: 20),
              
              // Statistics Cards
              _buildStatsCards(),
              const SizedBox(height: 20),
              
              // Low Stock Alert
              _buildLowStockAlert(),
              const SizedBox(height: 20),
              
              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppConstants.todayDate}: ${Helpers.formatDateKinyarwanda(DateTime.now())}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ThemeConfig.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mwakiriwe, ${authProvider.userDisplayName}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: ThemeConfig.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final stats = stockProvider.dashboardStats;
        
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    title: AppConstants.itemsInStock,
                    value: AppConstants.formatNumber(stats.itemsInStock),
                    subtitle: '${AppConstants.itemsInStock}',
                    icon: Icons.inventory,
                    color: ThemeConfig.primaryColor,
                    onTap: () => _onBottomNavTapped(2), // Go to products
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    title: AppConstants.todayReport,
                    value: AppConstants.formatNumber(stats.todaySalesCount),
                    subtitle: AppConstants.soldToday,
                    icon: Icons.trending_up,
                    color: ThemeConfig.successColor,
                    onTap: () => _onBottomNavTapped(3), // Go to reports
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    title: AppConstants.stockValue,
                    value: AppConstants.formatCurrency(stats.stockValue),
                    subtitle: AppConstants.currency,
                    icon: Icons.account_balance_wallet,
                    color: ThemeConfig.accentColor,
                    onTap: () => _onBottomNavTapped(2), // Go to products
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    title: AppConstants.damagedItems,
                    value: AppConstants.formatNumber(stats.todayDamagedCount),
                    subtitle: AppConstants.damagedItems,
                    icon: Icons.warning,
                    color: stats.todayDamagedCount > 0 
                        ? ThemeConfig.errorColor 
                        : ThemeConfig.secondaryText,
                    onTap: () => _onBottomNavTapped(1), // Go to stock management
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockAlert() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final stats = stockProvider.dashboardStats;
        
        if (stats == null || stats.lowStockProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: ThemeConfig.warningColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppConstants.lowStockAlert,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...stats.lowStockProducts.take(5).map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    StockStatusIndicator(stock: product.currentStock),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${product.productName}: ${product.currentStock} ${AppConstants.inStock}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              if (stats.lowStockProducts.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => _onBottomNavTapped(2),
                    child: Text(
                      'Reba byose (${stats.lowStockProducts.length})',
                      style: TextStyle(color: ThemeConfig.primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final movements = stockProvider.todayMovements.take(5).toList();
        
        if (movements.isEmpty) {
          return CustomCard(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: ThemeConfig.secondaryText,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nta bikorwa uyu munsi',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ThemeConfig.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tangira kwandika ibicuruzwa byinjiye cyangwa byagurishijwe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeConfig.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ibikorwa bya none',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _onBottomNavTapped(1),
                    child: Text(
                      'Reba byose',
                      style: TextStyle(color: ThemeConfig.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...movements.map((movement) => Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  final product = productProvider.getProductById(movement.productId);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getMovementColor(movement.movementType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMovementIcon(movement.movementType),
                            color: _getMovementColor(movement.movementType),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product?.productName ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${movement.movementType.displayName}: ${movement.quantity}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ThemeConfig.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Helpers.formatTime(movement.movementTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: _onBottomNavTapped,
      selectedItemColor: ThemeConfig.primaryColor,
      unselectedItemColor: ThemeConfig.secondaryText,
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, size: 28),
          label: AppConstants.navDashboard,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2, size: 28),
          label: AppConstants.navStock,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart, size: 28),
          label: AppConstants.navProducts,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment, size: 28),
          label: AppConstants.navReports,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: 28),
          label: AppConstants.navSettings,
        ),
      ],
    );
  }

  Color _getMovementColor(MovementType type) {
    switch (type) {
      case MovementType.BYINJIYE:
        return ThemeConfig.accentColor;
      case MovementType.BYAGURISHIJWE:
        return ThemeConfig.successColor;
      case MovementType.BYONGEWE:
        return ThemeConfig.errorColor;
    }
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.BYINJIYE:
        return Icons.add_box;
      case MovementType.BYAGURISHIJWE:
        return Icons.sell;
      case MovementType.BYONGEWE:
        return Icons.warning;
    }
  }
}
