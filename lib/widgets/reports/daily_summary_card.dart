import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../providers/stock_provider.dart';
import '../custom_card.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final stats = stockProvider.dashboardStats;
        
        if (stats == null) {
          return const CustomCard(
            child: Center(
              child: CircularProgressIndicator(),
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
                    'Incamake y\'Uyu Munsi',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Helpers.formatDateKinyarwanda(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeConfig.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Summary Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2,
                children: [
                  _buildStatItem(
                    context,
                    'Byagurishijwe',
                    '${stats.todaySalesCount}',
                    AppConstants.formatCurrency(stats.todaySalesAmount),
                    Icons.sell,
                    ThemeConfig.successColor,
                  ),
                  _buildStatItem(
                    context,
                    'Byinjiye',
                    '${stats.todayIncomingCount}',
                    'Ibicuruzwa',
                    Icons.add_box,
                    ThemeConfig.accentColor,
                  ),
                  _buildStatItem(
                    context,
                    'Byongewe',
                    '${stats.todayDamagedCount}',
                    AppConstants.formatCurrency(stats.todayDamageAmount),
                    Icons.warning,
                    ThemeConfig.errorColor,
                  ),
                  _buildStatItem(
                    context,
                    'Inyungu',
                    AppConstants.formatCurrency(stats.todayProfit),
                    'Uyu munsi',
                    Icons.trending_up,
                    ThemeConfig.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quick Summary Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ThemeConfig.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getSummaryText(stats),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeConfig.primaryText,
                        ),
                      ),
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

  Widget _buildStatItem(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeConfig.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSummaryText(dynamic stats) {
    if (stats.todaySalesCount == 0) {
      return 'Nta bicuruzwa byagurishijwe uyu munsi. Tangira gukora!';
    }
    
    if (stats.todayProfit > 0) {
      return 'Umunsi mwiza! Wungutse ${AppConstants.formatCurrency(stats.todayProfit)} uyu munsi.';
    }
    
    if (stats.todayDamagedCount > 0) {
      return 'Witondere ibicuruzwa byongewe (${stats.todayDamagedCount}). Reba impamvu.';
    }
    
    return 'Komeza gutuma ubucuruzi bwawe bugenda neza!';
  }
}
