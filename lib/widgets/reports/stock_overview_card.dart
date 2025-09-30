import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../utils/constants.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../custom_card.dart';
import '../stock_status_indicator.dart';

class StockOverviewCard extends StatelessWidget {
  const StockOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StockProvider, ProductProvider>(
      builder: (context, stockProvider, productProvider, child) {
        final stats = stockProvider.dashboardStats;
        final products = productProvider.products;
        
        if (stats == null || products.isEmpty) {
          return const CustomCard(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final lowStockProducts = stats.lowStockProducts;
        final outOfStockProducts = products.where((p) => p.currentStock <= 0).toList();

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ibikubiye muri Stock',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Stock Status Summary
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Byose',
                      '${products.length}',
                      'Ibicuruzwa',
                      Icons.inventory,
                      ThemeConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Stock Nke',
                      '${lowStockProducts.length}',
                      'Bikeneye',
                      Icons.warning,
                      ThemeConfig.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Byarangiye',
                      '${outOfStockProducts.length}',
                      'Ntibikiri',
                      Icons.error,
                      ThemeConfig.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Low Stock Alert
              if (lowStockProducts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeConfig.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.warningColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: ThemeConfig.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ibicuruzwa Bikeneye Stock',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeConfig.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...lowStockProducts.take(5).map((product) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            StockStatusIndicator(
                              stock: product.currentStock,
                              minStockLevel: product.minStockLevel,
                              size: 8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.productName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${product.currentStock}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.warningColor,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      if (lowStockProducts.length > 5)
                        Text(
                          '... n\'ibindi ${lowStockProducts.length - 5}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Out of Stock Alert
              if (outOfStockProducts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeConfig.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: ThemeConfig.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ibicuruzwa Byarangiye',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeConfig.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...outOfStockProducts.take(3).map((product) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            StockStatusIndicator(
                              stock: product.currentStock,
                              size: 8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.productName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              'Byarangiye',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeConfig.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      if (outOfStockProducts.length > 3)
                        Text(
                          '... n\'ibindi ${outOfStockProducts.length - 3}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Stock Value Summary
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agaciro ka Stock',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ThemeConfig.secondaryText,
                          ),
                        ),
                        Text(
                          AppConstants.formatCurrency(stats.stockValue),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: ThemeConfig.primaryColor,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.secondaryText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
