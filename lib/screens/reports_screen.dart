import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/stock_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/reports/daily_summary_card.dart';
import '../widgets/reports/sales_chart.dart';
import '../widgets/reports/stock_overview_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'Uyu munsi'; // Today, This Week, This Month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.navReports),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Sohora PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Vugurura',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConfig.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              
              // Daily Summary
              const DailySummaryCard(),
              const SizedBox(height: 20),
              
              // Sales Chart
              const SalesChart(),
              const SizedBox(height: 20),
              
              // Stock Overview
              const StockOverviewCard(),
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hitamo Igihe',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Period Chips
          Wrap(
            spacing: 8,
            children: [
              'Uyu munsi',
              'Iki cyumweru',
              'Uku kwezi',
            ].map((period) => _buildPeriodChip(period)).toList(),
          ),
          const SizedBox(height: 16),
          
          // Date Picker
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Itariki: ${Helpers.formatDate(_selectedDate)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    
    return FilterChip(
      label: Text(period),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = period;
          });
          _refreshData();
        }
      },
      selectedColor: ThemeConfig.primaryColor.withOpacity(0.2),
      checkmarkColor: ThemeConfig.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? ThemeConfig.primaryColor : ThemeConfig.secondaryText,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ibikorwa Byihuse',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildActionButton(
                'Raporo ya Stock',
                Icons.inventory,
                ThemeConfig.primaryColor,
                () => _generateStockReport(),
              ),
              _buildActionButton(
                'Raporo y\'Inyungu',
                Icons.trending_up,
                ThemeConfig.successColor,
                () => _generateSalesReport(),
              ),
              _buildActionButton(
                'Ibicuruzwa Byongewe',
                Icons.warning,
                ThemeConfig.errorColor,
                () => _generateDamageReport(),
              ),
              _buildActionButton(
                'Raporo Rusange',
                Icons.assessment,
                ThemeConfig.accentColor,
                () => _generateFullReport(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('rw'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriod = 'Itariki yihariye'; // Custom date
      });
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    await Future.wait([
      stockProvider.refreshData(),
      productProvider.refreshProducts(),
    ]);
  }

  Future<void> _exportToPDF() async {
    try {
      // Show loading
      Helpers.showLoadingDialog(context, 'Birateguriwa PDF...');
      
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      // Generate PDF report
      final success = await stockProvider.generatePDFReport(
        date: _selectedDate,
        period: _selectedPeriod,
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (success) {
          Helpers.showSuccessMessage(context, 'PDF yasohotse neza!');
        } else {
          Helpers.showErrorMessage(
            context, 
            stockProvider.errorMessage ?? 'Habayeho ikosa mu gusohora PDF',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Helpers.showErrorMessage(context, 'Habayeho ikosa: ${e.toString()}');
      }
    }
  }

  void _generateStockReport() {
    Helpers.showSuccessMessage(context, 'Raporo ya Stock irateguriwa...');
    // TODO: Implement stock report generation
  }

  void _generateSalesReport() {
    Helpers.showSuccessMessage(context, 'Raporo y\'Inyungu irateguriwa...');
    // TODO: Implement sales report generation
  }

  void _generateDamageReport() {
    Helpers.showSuccessMessage(context, 'Raporo y\'Ibicuruzwa Byongewe irateguriwa...');
    // TODO: Implement damage report generation
  }

  void _generateFullReport() {
    Helpers.showSuccessMessage(context, 'Raporo Rusange irateguriwa...');
    // TODO: Implement full report generation
  }
}
