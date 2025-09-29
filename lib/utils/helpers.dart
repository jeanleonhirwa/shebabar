import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  // Date formatting helpers
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatDateKinyarwanda(DateTime date) {
    final weekdays = [
      'Ku cyumweru',
      'Ku wa mbere',
      'Ku wa kabiri',
      'Ku wa gatatu',
      'Ku wa kane',
      'Ku wa gatanu',
      'Ku wa gatandatu'
    ];
    
    final months = [
      'Mutarama',
      'Gashyantare',
      'Werurwe',
      'Mata',
      'Gicuransi',
      'Kamena',
      'Nyakanga',
      'Kanama',
      'Nzeli',
      'Ukwakira',
      'Ugushyingo',
      'Ukuboza'
    ];

    return '${weekdays[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Show success message
  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show error message
  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                AppConstants.cancel,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                AppConstants.confirm,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Validate input fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${AppConstants.fieldRequired}';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${AppConstants.fieldRequired}';
    }
    if (int.tryParse(value) == null) {
      return AppConstants.invalidNumber;
    }
    if (int.parse(value) < 0) {
      return AppConstants.invalidNumber;
    }
    return null;
  }

  static String? validatePrice(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${AppConstants.fieldRequired}';
    }
    if (double.tryParse(value) == null) {
      return AppConstants.invalidPrice;
    }
    if (double.parse(value) <= 0) {
      return AppConstants.invalidPrice;
    }
    return null;
  }

  // Get stock status color
  static Color getStockStatusColor(int stock) {
    if (stock <= 2) {
      return Colors.red;
    } else if (stock <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Get stock status text
  static String getStockStatusText(int stock) {
    if (stock <= 0) {
      return AppConstants.outOfStock;
    } else if (stock <= 5) {
      return AppConstants.lowStock;
    } else {
      return AppConstants.stockOk;
    }
  }

  // Calculate closing stock
  static int calculateClosingStock(int opening, int incoming, int sold, int damaged) {
    return opening + incoming - sold - damaged;
  }

  // Get today's date range
  static DateTimeRange getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return DateTimeRange(start: today, end: tomorrow);
  }

  // Get this week's date range
  static DateTimeRange getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return DateTimeRange(start: start, end: end);
  }

  // Get this month's date range
  static DateTimeRange getThisMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DateTimeRange(start: start, end: end);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Generate report filename
  static String generateReportFilename(String type, DateTime startDate, DateTime? endDate) {
    final dateStr = endDate != null 
        ? '${formatDate(startDate)}_to_${formatDate(endDate)}'
        : formatDate(startDate);
    return 'ShebaBar_${type}_$dateStr.pdf';
  }

  // Debounce function for search
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
}

// Extension to add Timer import
import 'dart:async';
