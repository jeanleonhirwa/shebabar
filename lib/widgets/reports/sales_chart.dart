import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme_config.dart';
import '../../utils/constants.dart';
import '../../providers/stock_provider.dart';
import '../custom_card.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final salesData = stockProvider.weekSalesData;
        
        if (salesData.isEmpty) {
          return CustomCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inyungu z\'Iki Cyumweru',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.show_chart,
                      color: ThemeConfig.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: ThemeConfig.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nta makuru y\'inyungu',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ThemeConfig.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
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
                    'Inyungu z\'Iki Cyumweru',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ThemeConfig.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      AppConstants.formatCurrency(_getTotalSales(salesData)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeConfig.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Chart
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(salesData),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: ThemeConfig.primaryColor,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${_getDayName(groupIndex)}\n${AppConstants.formatCurrency(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getDayAbbreviation(value.toInt()),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ThemeConfig.secondaryText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatYAxisValue(value),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeConfig.secondaryText,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(salesData),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxY(salesData) / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: ThemeConfig.secondaryText.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Inyungu', ThemeConfig.successColor),
                  const SizedBox(width: 24),
                  _buildLegendItem('Igihombo', ThemeConfig.errorColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: ThemeConfig.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> salesData) {
    return salesData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['sales'] as double).abs(),
            color: data['sales'] >= 0 ? ThemeConfig.successColor : ThemeConfig.errorColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getTotalSales(List<Map<String, dynamic>> salesData) {
    return salesData.fold(0.0, (sum, data) => sum + (data['sales'] as double));
  }

  double _getMaxY(List<Map<String, dynamic>> salesData) {
    if (salesData.isEmpty) return 100000;
    
    final maxValue = salesData.fold(0.0, (max, data) {
      final value = (data['sales'] as double).abs();
      return value > max ? value : max;
    });
    
    // Add 20% padding to the max value
    return maxValue * 1.2;
  }

  String _getDayName(int index) {
    const days = [
      'Ku cyumweru',
      'Ku wa mbere',
      'Ku wa kabiri',
      'Ku wa gatatu',
      'Ku wa kane',
      'Ku wa gatanu',
      'Ku wa gatandatu',
    ];
    return index < days.length ? days[index] : '';
  }

  String _getDayAbbreviation(int index) {
    const days = ['Cyu', 'Mbe', 'Kab', 'Gat', 'Kan', 'Gat', 'Gat'];
    return index < days.length ? days[index] : '';
  }

  String _formatYAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
