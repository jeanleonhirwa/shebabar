import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/stock_status_indicator.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProductCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.navProducts),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.canManageProducts) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddProductDialog(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilter(),
          
          // Products List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.products.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => productProvider.refreshProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConfig.screenPadding),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.screenPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppConstants.search,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(null, 'Byose'),
                ...ProductCategory.values.map(
                  (category) => _buildCategoryChip(category, category.displayName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ProductCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _onCategoryChanged(category);
        },
        selectedColor: ThemeConfig.primaryColor.withOpacity(0.2),
        checkmarkColor: ThemeConfig.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? ThemeConfig.primaryColor : ThemeConfig.secondaryText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        onTap: () => _showProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(product.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(product.category),
                    color: _getCategoryColor(product.category),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stock Status
                StockStatusIndicator(
                  stock: product.currentStock,
                  minStockLevel: product.minStockLevel,
                  showText: false,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock and Price Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Stock',
                    '${product.currentStock}',
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    AppConstants.price,
                    AppConstants.formatCurrency(product.unitPrice),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Agaciro',
                    AppConstants.formatCurrency(product.totalValue),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: ThemeConfig.secondaryText,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.secondaryText,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: ThemeConfig.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Nta bicuruzwa',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ThemeConfig.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ongeraho ibicuruzwa kugirango utangire',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeConfig.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.canManageProducts) {
                return ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ongeraho Icyicuruzwa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);
  }

  void _onCategoryChanged(ProductCategory? category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.filterByCategory(category);
  }

  void _showProductDetails(Product product) {
    // TODO: Navigate to product details screen
    Helpers.showSuccessMessage(context, 'Product details: ${product.productName}');
  }

  void _showAddProductDialog() {
    // TODO: Show add product dialog
    Helpers.showSuccessMessage(context, 'Add product dialog coming soon...');
  }

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.INZOGA_NINI:
        return Colors.amber;
      case ProductCategory.INZOGA_NTO:
        return Colors.orange;
      case ProductCategory.IBINYOBWA_BIDAFITE_ALCOHOL:
        return Colors.blue;
      case ProductCategory.VINO:
        return Colors.purple;
      case ProductCategory.SPIRITS:
        return Colors.red;
      case ProductCategory.AMAZI:
        return Colors.cyan;
    }
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.INZOGA_NINI:
        return Icons.sports_bar;
      case ProductCategory.INZOGA_NTO:
        return Icons.local_bar;
      case ProductCategory.IBINYOBWA_BIDAFITE_ALCOHOL:
        return Icons.local_drink;
      case ProductCategory.VINO:
        return Icons.wine_bar;
      case ProductCategory.SPIRITS:
        return Icons.liquor;
      case ProductCategory.AMAZI:
        return Icons.water_drop;
    }
  }
}
