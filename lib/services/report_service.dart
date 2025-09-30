import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'database_service.dart';
import 'auth_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // Generate daily report
  Future<ReportResult> generateDailyReport(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get movements for the day
      final movements = await _databaseService.getStockMovements(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Get products
      final products = await _databaseService.getAllProducts();
      final productMap = {for (var p in products) p.productId!: p};

      // Calculate totals
      final reportData = _calculateReportData(movements, productMap);

      // Create report
      final report = DailyReport(
        date: date,
        openingStockValue: 0.0, // Would need to calculate from previous day
        incomingQuantity: reportData['incomingQuantity'],
        incomingValue: reportData['incomingValue'],
        soldQuantity: reportData['soldQuantity'],
        soldValue: reportData['soldValue'],
        damagedQuantity: reportData['damagedQuantity'],
        damagedValue: reportData['damagedValue'],
        closingStockValue: _calculateCurrentStockValue(products),
        movements: movements,
        productBreakdown: _generateProductBreakdown(movements, productMap),
      );

      return ReportResult.success(report);
    } catch (e) {
      return ReportResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Generate weekly report
  Future<ReportResult> generateWeeklyReport(DateTime startDate) async {
    try {
      final endDate = startDate.add(const Duration(days: 7));

      // Get movements for the week
      final movements = await _databaseService.getStockMovements(
        startDate: startDate,
        endDate: endDate,
      );

      // Get products
      final products = await _databaseService.getAllProducts();
      final productMap = {for (var p in products) p.productId!: p};

      // Calculate totals
      final reportData = _calculateReportData(movements, productMap);

      // Create report
      final report = WeeklyReport(
        startDate: startDate,
        endDate: endDate.subtract(const Duration(days: 1)),
        totalSoldQuantity: reportData['soldQuantity'],
        totalSoldValue: reportData['soldValue'],
        totalIncomingQuantity: reportData['incomingQuantity'],
        totalIncomingValue: reportData['incomingValue'],
        totalDamagedQuantity: reportData['damagedQuantity'],
        totalDamagedValue: reportData['damagedValue'],
        dailyBreakdown: await _generateDailyBreakdown(startDate, endDate),
        productBreakdown: _generateProductBreakdown(movements, productMap),
      );

      return ReportResult.success(report);
    } catch (e) {
      return ReportResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Generate monthly report
  Future<ReportResult> generateMonthlyReport(DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 1);

      // Get movements for the month
      final movements = await _databaseService.getStockMovements(
        startDate: startDate,
        endDate: endDate,
      );

      // Get products
      final products = await _databaseService.getAllProducts();
      final productMap = {for (var p in products) p.productId!: p};

      // Calculate totals
      final reportData = _calculateReportData(movements, productMap);

      // Create report
      final report = MonthlyReport(
        month: month,
        totalSoldQuantity: reportData['soldQuantity'],
        totalSoldValue: reportData['soldValue'],
        totalIncomingQuantity: reportData['incomingQuantity'],
        totalIncomingValue: reportData['incomingValue'],
        totalDamagedQuantity: reportData['damagedQuantity'],
        totalDamagedValue: reportData['damagedValue'],
        weeklyBreakdown: await _generateWeeklyBreakdown(startDate, endDate),
        productBreakdown: _generateProductBreakdown(movements, productMap),
        categoryBreakdown: _generateCategoryBreakdown(movements, productMap),
      );

      return ReportResult.success(report);
    } catch (e) {
      return ReportResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Generate PDF report
  Future<PDFResult> generatePDFReport(dynamic report) async {
    try {
      // Check permissions
      if (!_authService.hasPermission(Permission.exportReports)) {
        return PDFResult.failure('Ntufite uburenganzira bwo gusohora raporo');
      }

      final pdf = pw.Document();

      if (report is DailyReport) {
        await _addDailyReportPages(pdf, report);
      } else if (report is WeeklyReport) {
        await _addWeeklyReportPages(pdf, report);
      } else if (report is MonthlyReport) {
        await _addMonthlyReportPages(pdf, report);
      }

      final pdfBytes = await pdf.save();
      return PDFResult.success(pdfBytes);
    } catch (e) {
      return PDFResult.failure('Habayeho ikosa: ${e.toString()}');
    }
  }

  // Print report
  Future<void> printReport(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  // Share report
  Future<void> shareReport(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateReportData(
    List<StockMovement> movements,
    Map<int, Product> productMap,
  ) {
    int incomingQuantity = 0;
    double incomingValue = 0.0;
    int soldQuantity = 0;
    double soldValue = 0.0;
    int damagedQuantity = 0;
    double damagedValue = 0.0;

    for (final movement in movements) {
      switch (movement.movementType) {
        case MovementType.BYINJIYE:
          incomingQuantity += movement.quantity;
          incomingValue += movement.totalAmount;
          break;
        case MovementType.BYAGURISHIJWE:
          soldQuantity += movement.quantity;
          soldValue += movement.totalAmount;
          break;
        case MovementType.BYONGEWE:
          damagedQuantity += movement.quantity;
          damagedValue += movement.totalAmount;
          break;
      }
    }

    return {
      'incomingQuantity': incomingQuantity,
      'incomingValue': incomingValue,
      'soldQuantity': soldQuantity,
      'soldValue': soldValue,
      'damagedQuantity': damagedQuantity,
      'damagedValue': damagedValue,
    };
  }

  double _calculateCurrentStockValue(List<Product> products) {
    return products.fold(0.0, (sum, product) => sum + product.totalValue);
  }

  List<ProductBreakdown> _generateProductBreakdown(
    List<StockMovement> movements,
    Map<int, Product> productMap,
  ) {
    final Map<int, ProductBreakdown> breakdownMap = {};

    for (final movement in movements) {
      final product = productMap[movement.productId];
      if (product == null) continue;

      if (!breakdownMap.containsKey(movement.productId)) {
        breakdownMap[movement.productId] = ProductBreakdown(
          productId: movement.productId,
          productName: product.productName,
          category: product.category,
          unitPrice: product.unitPrice,
          incomingQuantity: 0,
          soldQuantity: 0,
          damagedQuantity: 0,
          soldValue: 0.0,
          damagedValue: 0.0,
        );
      }

      final breakdown = breakdownMap[movement.productId]!;
      switch (movement.movementType) {
        case MovementType.BYINJIYE:
          breakdownMap[movement.productId] = breakdown.copyWith(
            incomingQuantity: breakdown.incomingQuantity + movement.quantity,
          );
          break;
        case MovementType.BYAGURISHIJWE:
          breakdownMap[movement.productId] = breakdown.copyWith(
            soldQuantity: breakdown.soldQuantity + movement.quantity,
            soldValue: breakdown.soldValue + movement.totalAmount,
          );
          break;
        case MovementType.BYONGEWE:
          breakdownMap[movement.productId] = breakdown.copyWith(
            damagedQuantity: breakdown.damagedQuantity + movement.quantity,
            damagedValue: breakdown.damagedValue + movement.totalAmount,
          );
          break;
      }
    }

    final breakdownList = breakdownMap.values.toList();
    breakdownList.sort((a, b) => b.soldValue.compareTo(a.soldValue));
    return breakdownList;
  }

  Map<ProductCategory, CategoryBreakdown> _generateCategoryBreakdown(
    List<StockMovement> movements,
    Map<int, Product> productMap,
  ) {
    final Map<ProductCategory, CategoryBreakdown> breakdownMap = {};

    for (final movement in movements) {
      final product = productMap[movement.productId];
      if (product == null) continue;

      if (!breakdownMap.containsKey(product.category)) {
        breakdownMap[product.category] = CategoryBreakdown(
          category: product.category,
          soldQuantity: 0,
          soldValue: 0.0,
          damagedQuantity: 0,
          damagedValue: 0.0,
        );
      }

      final breakdown = breakdownMap[product.category]!;
      switch (movement.movementType) {
        case MovementType.BYAGURISHIJWE:
          breakdownMap[product.category] = breakdown.copyWith(
            soldQuantity: breakdown.soldQuantity + movement.quantity,
            soldValue: breakdown.soldValue + movement.totalAmount,
          );
          break;
        case MovementType.BYONGEWE:
          breakdownMap[product.category] = breakdown.copyWith(
            damagedQuantity: breakdown.damagedQuantity + movement.quantity,
            damagedValue: breakdown.damagedValue + movement.totalAmount,
          );
          break;
        default:
          break;
      }
    }

    return breakdownMap;
  }

  Future<List<DailyBreakdown>> _generateDailyBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<DailyBreakdown> dailyBreakdown = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate)) {
      final nextDay = currentDate.add(const Duration(days: 1));
      final movements = await _databaseService.getStockMovements(
        startDate: currentDate,
        endDate: nextDay,
      );

      final products = await _databaseService.getAllProducts();
      final productMap = {for (var p in products) p.productId!: p};
      final reportData = _calculateReportData(movements, productMap);

      dailyBreakdown.add(DailyBreakdown(
        date: currentDate,
        soldQuantity: reportData['soldQuantity'],
        soldValue: reportData['soldValue'],
        damagedQuantity: reportData['damagedQuantity'],
        damagedValue: reportData['damagedValue'],
      ));

      currentDate = nextDay;
    }

    return dailyBreakdown;
  }

  Future<List<WeeklyBreakdown>> _generateWeeklyBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<WeeklyBreakdown> weeklyBreakdown = [];
    DateTime currentWeekStart = startDate;

    while (currentWeekStart.isBefore(endDate)) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
      final actualWeekEnd = currentWeekEnd.isAfter(endDate) ? endDate : currentWeekEnd;

      final movements = await _databaseService.getStockMovements(
        startDate: currentWeekStart,
        endDate: actualWeekEnd,
      );

      final products = await _databaseService.getAllProducts();
      final productMap = {for (var p in products) p.productId!: p};
      final reportData = _calculateReportData(movements, productMap);

      weeklyBreakdown.add(WeeklyBreakdown(
        startDate: currentWeekStart,
        endDate: actualWeekEnd.subtract(const Duration(days: 1)),
        soldQuantity: reportData['soldQuantity'],
        soldValue: reportData['soldValue'],
        damagedQuantity: reportData['damagedQuantity'],
        damagedValue: reportData['damagedValue'],
      ));

      currentWeekStart = currentWeekEnd;
    }

    return weeklyBreakdown;
  }

  // PDF generation methods
  Future<void> _addDailyReportPages(pw.Document pdf, DailyReport report) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      AppConstants.appName,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'RAPORO Y\'UMUNSI',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      Helpers.formatDate(report.date),
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary section
              pw.Text(
                'INCAMAKE:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              
              _buildSummaryTable(report),
              
              pw.SizedBox(height: 20),
              
              // Product breakdown
              pw.Text(
                'IBICURUZWA BYAGURISHIJWE:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              
              _buildProductBreakdownTable(report.productBreakdown),
              
              pw.Spacer(),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Byanditswe na: ${_authService.currentUser?.fullName ?? ''}'),
                  pw.Text('Italiki: ${Helpers.formatDateTime(DateTime.now())}'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addWeeklyReportPages(pw.Document pdf, WeeklyReport report) async {
    // Similar implementation for weekly report
  }

  Future<void> _addMonthlyReportPages(pw.Document pdf, MonthlyReport report) async {
    // Similar implementation for monthly report
  }

  pw.Widget _buildSummaryTable(DailyReport report) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        _buildTableRow('Byagurishijwe:', '${report.soldQuantity} ibicuruzwa'),
        _buildTableRow('Amafaranga:', AppConstants.formatCurrency(report.soldValue)),
        _buildTableRow('Byongewe:', '${report.damagedQuantity} ibicuruzwa'),
        _buildTableRow('Igihombo:', AppConstants.formatCurrency(report.damagedValue)),
        _buildTableRow('Stock ifunze:', AppConstants.formatCurrency(report.closingStockValue)),
      ],
    );
  }

  pw.Widget _buildProductBreakdownTable(List<ProductBreakdown> breakdown) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Icyicuruzwa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Ingano', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Agaciro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...breakdown.take(20).map((item) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(item.productName),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('${item.soldQuantity}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(AppConstants.formatCurrency(item.soldValue)),
            ),
          ],
        )),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}

// Report classes
class DailyReport {
  final DateTime date;
  final double openingStockValue;
  final int incomingQuantity;
  final double incomingValue;
  final int soldQuantity;
  final double soldValue;
  final int damagedQuantity;
  final double damagedValue;
  final double closingStockValue;
  final List<StockMovement> movements;
  final List<ProductBreakdown> productBreakdown;

  DailyReport({
    required this.date,
    required this.openingStockValue,
    required this.incomingQuantity,
    required this.incomingValue,
    required this.soldQuantity,
    required this.soldValue,
    required this.damagedQuantity,
    required this.damagedValue,
    required this.closingStockValue,
    required this.movements,
    required this.productBreakdown,
  });
}

class WeeklyReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalSoldQuantity;
  final double totalSoldValue;
  final int totalIncomingQuantity;
  final double totalIncomingValue;
  final int totalDamagedQuantity;
  final double totalDamagedValue;
  final List<DailyBreakdown> dailyBreakdown;
  final List<ProductBreakdown> productBreakdown;

  WeeklyReport({
    required this.startDate,
    required this.endDate,
    required this.totalSoldQuantity,
    required this.totalSoldValue,
    required this.totalIncomingQuantity,
    required this.totalIncomingValue,
    required this.totalDamagedQuantity,
    required this.totalDamagedValue,
    required this.dailyBreakdown,
    required this.productBreakdown,
  });
}

class MonthlyReport {
  final DateTime month;
  final int totalSoldQuantity;
  final double totalSoldValue;
  final int totalIncomingQuantity;
  final double totalIncomingValue;
  final int totalDamagedQuantity;
  final double totalDamagedValue;
  final List<WeeklyBreakdown> weeklyBreakdown;
  final List<ProductBreakdown> productBreakdown;
  final Map<ProductCategory, CategoryBreakdown> categoryBreakdown;

  MonthlyReport({
    required this.month,
    required this.totalSoldQuantity,
    required this.totalSoldValue,
    required this.totalIncomingQuantity,
    required this.totalIncomingValue,
    required this.totalDamagedQuantity,
    required this.totalDamagedValue,
    required this.weeklyBreakdown,
    required this.productBreakdown,
    required this.categoryBreakdown,
  });
}

// Breakdown classes
class ProductBreakdown {
  final int productId;
  final String productName;
  final ProductCategory category;
  final double unitPrice;
  final int incomingQuantity;
  final int soldQuantity;
  final int damagedQuantity;
  final double soldValue;
  final double damagedValue;

  ProductBreakdown({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.incomingQuantity,
    required this.soldQuantity,
    required this.damagedQuantity,
    required this.soldValue,
    required this.damagedValue,
  });

  ProductBreakdown copyWith({
    int? incomingQuantity,
    int? soldQuantity,
    int? damagedQuantity,
    double? soldValue,
    double? damagedValue,
  }) {
    return ProductBreakdown(
      productId: productId,
      productName: productName,
      category: category,
      unitPrice: unitPrice,
      incomingQuantity: incomingQuantity ?? this.incomingQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      damagedQuantity: damagedQuantity ?? this.damagedQuantity,
      soldValue: soldValue ?? this.soldValue,
      damagedValue: damagedValue ?? this.damagedValue,
    );
  }
}

class CategoryBreakdown {
  final ProductCategory category;
  final int soldQuantity;
  final double soldValue;
  final int damagedQuantity;
  final double damagedValue;

  CategoryBreakdown({
    required this.category,
    required this.soldQuantity,
    required this.soldValue,
    required this.damagedQuantity,
    required this.damagedValue,
  });

  CategoryBreakdown copyWith({
    int? soldQuantity,
    double? soldValue,
    int? damagedQuantity,
    double? damagedValue,
  }) {
    return CategoryBreakdown(
      category: category,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      soldValue: soldValue ?? this.soldValue,
      damagedQuantity: damagedQuantity ?? this.damagedQuantity,
      damagedValue: damagedValue ?? this.damagedValue,
    );
  }
}

class DailyBreakdown {
  final DateTime date;
  final int soldQuantity;
  final double soldValue;
  final int damagedQuantity;
  final double damagedValue;

  DailyBreakdown({
    required this.date,
    required this.soldQuantity,
    required this.soldValue,
    required this.damagedQuantity,
    required this.damagedValue,
  });
}

class WeeklyBreakdown {
  final DateTime startDate;
  final DateTime endDate;
  final int soldQuantity;
  final double soldValue;
  final int damagedQuantity;
  final double damagedValue;

  WeeklyBreakdown({
    required this.startDate,
    required this.endDate,
    required this.soldQuantity,
    required this.soldValue,
    required this.damagedQuantity,
    required this.damagedValue,
  });
}

// Result classes
class ReportResult {
  final bool success;
  final String? message;
  final dynamic report;

  ReportResult._(this.success, this.message, this.report);

  factory ReportResult.success(dynamic report) {
    return ReportResult._(true, null, report);
  }

  factory ReportResult.failure(String message) {
    return ReportResult._(false, message, null);
  }
}

class PDFResult {
  final bool success;
  final String? message;
  final List<int>? pdfBytes;

  PDFResult._(this.success, this.message, this.pdfBytes);

  factory PDFResult.success(List<int> pdfBytes) {
    return PDFResult._(true, null, pdfBytes);
  }

  factory PDFResult.failure(String message) {
    return PDFResult._(false, message, null);
  }
}
