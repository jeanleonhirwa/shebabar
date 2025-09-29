import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../utils/constants.dart';
import '../providers/stock_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/stock_tabs/incoming_tab.dart';
import '../widgets/stock_tabs/sales_tab.dart';
import '../widgets/stock_tabs/damaged_tab.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      stockProvider.initialize();
      productProvider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.navStock),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeConfig.primaryColor,
          labelColor: ThemeConfig.primaryColor,
          unselectedLabelColor: ThemeConfig.secondaryText,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.add_box),
              text: 'Byinjiye',
            ),
            Tab(
              icon: Icon(Icons.sell),
              text: 'Byagurishijwe',
            ),
            Tab(
              icon: Icon(Icons.warning),
              text: 'Byongewe',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IncomingTab(),
          SalesTab(),
          DamagedTab(),
        ],
      ),
    );
  }
}
