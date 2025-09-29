import 'constants.dart';

class Validators {
  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${AppConstants.username} ${AppConstants.fieldRequired}';
    }
    if (value.trim().length < 3) {
      return 'Izina rigomba kuba rifite ibyangombwa 3 byibuze';
    }
    if (value.trim().length > 20) {
      return 'Izina ntirirenze ibyangombwa 20';
    }
    // Allow only letters, numbers, and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Izina rikoresha ibyangombwa bitemewe gusa';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '${AppConstants.password} ${AppConstants.fieldRequired}';
    }
    if (value.length < 4) {
      return 'Ijambo ryibanga rigomba kuba rifite ibyangombwa 4 byibuze';
    }
    return null;
  }

  // Product name validation
  static String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${AppConstants.productName} ${AppConstants.fieldRequired}';
    }
    if (value.trim().length < 2) {
      return 'Izina ry\'icyicuruzwa rigomba kuba rifite ibyangombwa 2 byibuze';
    }
    if (value.trim().length > 50) {
      return 'Izina ry\'icyicuruzwa ntirirenze ibyangombwa 50';
    }
    return null;
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${AppConstants.price} ${AppConstants.fieldRequired}';
    }
    
    final price = double.tryParse(value.trim());
    if (price == null) {
      return AppConstants.invalidPrice;
    }
    
    if (price <= 0) {
      return 'Igiciro kigomba kuba kirenze 0';
    }
    
    if (price > 1000000) {
      return 'Igiciro ntikigomba kurenza 1,000,000';
    }
    
    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${AppConstants.enterQuantity} ${AppConstants.fieldRequired}';
    }
    
    final quantity = int.tryParse(value.trim());
    if (quantity == null) {
      return AppConstants.invalidNumber;
    }
    
    if (quantity < 0) {
      return 'Ingano ntishobora kuba munsi ya 0';
    }
    
    if (quantity > 10000) {
      return 'Ingano ntishobora kurenza 10,000';
    }
    
    return null;
  }

  // Stock validation for sales
  static String? validateSaleQuantity(String? value, int availableStock) {
    final quantityError = validateQuantity(value);
    if (quantityError != null) {
      return quantityError;
    }
    
    final quantity = int.parse(value!.trim());
    if (quantity > availableStock) {
      return '${AppConstants.insufficientStock}. Biri muri stock: $availableStock';
    }
    
    return null;
  }

  // Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amazina ${AppConstants.fieldRequired}';
    }
    if (value.trim().length < 2) {
      return 'Amazina agomba kuba afite ibyangombwa 2 byibuze';
    }
    if (value.trim().length > 50) {
      return 'Amazina ntayirenze ibyangombwa 50';
    }
    // Allow letters, spaces, and common punctuation
    if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(value.trim())) {
      return 'Amazina akoresha ibyangombwa bitemewe gusa';
    }
    return null;
  }

  // Notes validation (optional field)
  static String? validateNotes(String? value) {
    if (value != null && value.trim().length > 200) {
      return 'Inyandiko ntizirenze ibyangombwa 200';
    }
    return null;
  }

  // Email validation (for future use)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email ntikwiye';
    }
    
    return null;
  }

  // Phone number validation (for future use)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Rwanda phone number format: +250XXXXXXXXX or 07XXXXXXXX
    final phoneRegex = RegExp(r'^(\+250|07)\d{8}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Nimero ya telefoni ntikwiye';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return '${AppConstants.todayDate} ${AppConstants.fieldRequired}';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    // Don't allow future dates for stock movements
    if (selectedDate.isAfter(today)) {
      return 'Ntushobora guhitamo italiki izaza';
    }
    
    // Don't allow dates more than 1 year ago
    final oneYearAgo = today.subtract(const Duration(days: 365));
    if (selectedDate.isBefore(oneYearAgo)) {
      return 'Ntushobora guhitamo italiki ishize amezi 12';
    }
    
    return null;
  }

  // Min stock level validation
  static String? validateMinStockLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock ntoya ${AppConstants.fieldRequired}';
    }
    
    final minStock = int.tryParse(value.trim());
    if (minStock == null) {
      return AppConstants.invalidNumber;
    }
    
    if (minStock < 0) {
      return 'Stock ntoya ntishobora kuba munsi ya 0';
    }
    
    if (minStock > 100) {
      return 'Stock ntoya ntishobora kurenza 100';
    }
    
    return null;
  }

  // Search query validation
  static String? validateSearchQuery(String? value) {
    if (value != null && value.trim().length > 50) {
      return 'Icyo ushakisha ntikigomba kurenza ibyangombwa 50';
    }
    return null;
  }

  // Generic numeric range validation
  static String? validateNumericRange(String? value, String fieldName, int min, int max) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${AppConstants.fieldRequired}';
    }
    
    final number = int.tryParse(value.trim());
    if (number == null) {
      return AppConstants.invalidNumber;
    }
    
    if (number < min || number > max) {
      return '$fieldName igomba kuba hagati ya $min na $max';
    }
    
    return null;
  }

  // Generic decimal range validation
  static String? validateDecimalRange(String? value, String fieldName, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${AppConstants.fieldRequired}';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return AppConstants.invalidPrice;
    }
    
    if (number < min || number > max) {
      return '$fieldName igomba kuba hagati ya $min na $max';
    }
    
    return null;
  }
}
