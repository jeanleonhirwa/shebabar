import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../config/app_config.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../custom_card.dart';

class IncomingTab extends StatefulWidget {
  const IncomingTab({super.key});

  @override
  State<IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<IncomingTab> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  Product? _selectedProduct;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.screenPadding),
      child: Column(
        children: [
          // Form Section
          _buildForm(),
          const SizedBox(height: 20),
          
          // Recent Incoming Items
          Expanded(
            child: _buildRecentItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return CustomCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Andika Ibicuruzwa Byinjiye',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Product Dropdown
            _buildProductDropdown(),
            const SizedBox(height: 16),
            
            // Quantity Field
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ingano',
                prefixIcon: Icon(Icons.numbers),
                hintText: 'Shyiramo ingano yinjiye',
              ),
              validator: Validators.validateQuantity,
            ),
            const SizedBox(height: 16),
            
            // Notes Field
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Inyandiko (Ntabwo ari ngombwa)',
                prefixIcon: Icon(Icons.note),
                hintText: 'Andika inyandiko...',
              ),
              validator: Validators.validateNotes,
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: AppConfig.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.accentColor,
                  foregroundColor: Colors.white,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_box),
                label: Text(
                  _isSubmitting ? 'Birakora...' : 'Andika Byinjiye',
                  style: const TextStyle(
                    fontSize: AppConfig.buttonFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.activeProducts;
        
        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: ThemeConfig.secondaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nta bicuruzwa biboneka. Ongeraho ibicuruzwa mbere.',
                    style: TextStyle(color: ThemeConfig.secondaryText),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<Product>(
          value: _selectedProduct,
          decoration: const InputDecoration(
            labelText: AppConstants.productName,
            prefixIcon: Icon(Icons.inventory),
          ),
          items: products.map((product) {
            return DropdownMenuItem<Product>(
              value: product,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStockStatusColor(product.currentStock),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${product.productName} (${product.currentStock})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (product) {
            setState(() {
              _selectedProduct = product;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Hitamo icyicuruzwa';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildRecentItems() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final incomingMovements = stockProvider.incomingMovements;
        
        if (incomingMovements.isEmpty) {
          return CustomCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 64,
                    color: ThemeConfig.secondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nta bicuruzwa byinjiye uyu munsi',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ThemeConfig.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Byinjiye Uyu Munsi (${incomingMovements.length})',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: incomingMovements.length,
                itemBuilder: (context, index) {
                  final movement = incomingMovements[index];
                  return _buildMovementCard(movement);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.getProductById(movement.productId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CustomCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ThemeConfig.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_box,
                    color: ThemeConfig.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.productName ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Ingano: ${movement.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.secondaryText,
                        ),
                      ),
                      if (movement.notes?.isNotEmpty == true)
                        Text(
                          movement.notes!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ),
        );
      },
    );
  }

  Color _getStockStatusColor(int stock) {
    if (stock <= 0) {
      return ThemeConfig.errorColor;
    } else if (stock <= 5) {
      return ThemeConfig.warningColor;
    } else {
      return ThemeConfig.successColor;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      final success = await stockProvider.recordIncoming(
        productId: _selectedProduct!.productId!,
        quantity: int.parse(_quantityController.text.trim()),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          // Clear form
          _quantityController.clear();
          _notesController.clear();
          setState(() {
            _selectedProduct = null;
          });
          
          Helpers.showSuccessMessage(context, AppConstants.saved);
        } else {
          Helpers.showErrorMessage(
            context, 
            stockProvider.errorMessage ?? AppConstants.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorMessage(context, 'Habayeho ikosa: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
