import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class StockStatusIndicator extends StatelessWidget {
  final int stock;
  final int? minStockLevel;
  final bool showText;
  final double size;

  const StockStatusIndicator({
    super.key,
    required this.stock,
    this.minStockLevel,
    this.showText = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final text = _getStatusText();

    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(color),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return _buildIndicator(color);
  }

  Widget _buildIndicator(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (stock <= 0) {
      return ThemeConfig.errorColor;
    } else if (stock <= (minStockLevel ?? AppConfig.criticalStockThreshold)) {
      return ThemeConfig.errorColor;
    } else if (stock <= (minStockLevel ?? AppConfig.lowStockThreshold)) {
      return ThemeConfig.warningColor;
    } else {
      return ThemeConfig.successColor;
    }
  }

  String _getStatusText() {
    if (stock <= 0) {
      return AppConstants.outOfStock;
    } else if (stock <= (minStockLevel ?? AppConfig.criticalStockThreshold)) {
      return AppConstants.stockCritical;
    } else if (stock <= (minStockLevel ?? AppConfig.lowStockThreshold)) {
      return AppConstants.lowStock;
    } else {
      return AppConstants.stockOk;
    }
  }
}

class StockLevelBar extends StatelessWidget {
  final int currentStock;
  final int maxStock;
  final int? minStockLevel;
  final double height;
  final bool showLabels;

  const StockLevelBar({
    super.key,
    required this.currentStock,
    required this.maxStock,
    this.minStockLevel,
    this.height = 8,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxStock > 0 ? (currentStock / maxStock).clamp(0.0, 1.0) : 0.0;
    final color = _getBarColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock: $currentStock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Max: $maxStock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        Container(
          height: height,
          decoration: BoxDecoration(
            color: ThemeConfig.secondaryBackground,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        
        if (showLabels && minStockLevel != null) ...[
          const SizedBox(height: 4),
          Text(
            'Ntoya: $minStockLevel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Color _getBarColor() {
    if (currentStock <= 0) {
      return ThemeConfig.errorColor;
    } else if (currentStock <= (minStockLevel ?? AppConfig.criticalStockThreshold)) {
      return ThemeConfig.errorColor;
    } else if (currentStock <= (minStockLevel ?? AppConfig.lowStockThreshold)) {
      return ThemeConfig.warningColor;
    } else {
      return ThemeConfig.successColor;
    }
  }
}

class StockBadge extends StatelessWidget {
  final int stock;
  final int? minStockLevel;
  final bool compact;

  const StockBadge({
    super.key,
    required this.stock,
    this.minStockLevel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    final text = compact ? '$stock' : _getBadgeText();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 12 : 14,
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    if (stock <= 0) {
      return ThemeConfig.errorColor;
    } else if (stock <= (minStockLevel ?? AppConfig.criticalStockThreshold)) {
      return ThemeConfig.errorColor;
    } else if (stock <= (minStockLevel ?? AppConfig.lowStockThreshold)) {
      return ThemeConfig.warningColor;
    } else {
      return ThemeConfig.successColor;
    }
  }

  String _getBadgeText() {
    if (stock <= 0) {
      return '0 - ${AppConstants.outOfStock}';
    } else if (stock <= (minStockLevel ?? AppConfig.criticalStockThreshold)) {
      return '$stock - ${AppConstants.stockCritical}';
    } else if (stock <= (minStockLevel ?? AppConfig.lowStockThreshold)) {
      return '$stock - ${AppConstants.lowStock}';
    } else {
      return '$stock - ${AppConstants.stockOk}';
    }
  }
}

class StockTrend extends StatelessWidget {
  final List<int> stockHistory;
  final double width;
  final double height;
  final Color? color;

  const StockTrend({
    super.key,
    required this.stockHistory,
    this.width = 100,
    this.height = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (stockHistory.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    final maxStock = stockHistory.reduce((a, b) => a > b ? a : b);
    final minStock = stockHistory.reduce((a, b) => a < b ? a : b);
    final range = maxStock - minStock;
    
    if (range == 0) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: (color ?? ThemeConfig.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            width: width * 0.8,
            height: 2,
            color: color ?? ThemeConfig.primaryColor,
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(width, height),
      painter: StockTrendPainter(
        stockHistory: stockHistory,
        color: color ?? ThemeConfig.primaryColor,
        maxStock: maxStock,
        minStock: minStock,
      ),
    );
  }
}

class StockTrendPainter extends CustomPainter {
  final List<int> stockHistory;
  final Color color;
  final int maxStock;
  final int minStock;

  StockTrendPainter({
    required this.stockHistory,
    required this.color,
    required this.maxStock,
    required this.minStock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stockHistory.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final range = maxStock - minStock;
    
    for (int i = 0; i < stockHistory.length; i++) {
      final x = (i / (stockHistory.length - 1)) * size.width;
      final y = size.height - ((stockHistory[i] - minStock) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stockHistory.length; i++) {
      final x = (i / (stockHistory.length - 1)) * size.width;
      final y = size.height - ((stockHistory[i] - minStock) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
