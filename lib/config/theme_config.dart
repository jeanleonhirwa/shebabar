import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_config.dart';

class ThemeConfig {
  // Color Scheme for Sheba Bar
  static const Color primaryColor = Color(0xFF2E7D32); // Green - growth, money
  static const Color secondaryColor = Color(0xFFFFA726); // Orange - warning, attention
  static const Color accentColor = Color(0xFF1976D2); // Blue - trust, technology
  
  // Status Colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color infoColor = Color(0xFF2196F3); // Blue
  
  // Background Colors
  static const Color primaryBackground = Color(0xFFFFFFFF); // White
  static const Color secondaryBackground = Color(0xFFF5F5F5); // Light gray
  static const Color cardBackground = Color(0xFFFFFFFF); // White with shadow
  
  // Text Colors
  static const Color primaryText = Color(0xFF212121); // Almost black
  static const Color secondaryText = Color(0xFF757575); // Gray
  static const Color disabledText = Color(0xFFBDBDBD); // Light gray
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on colored backgrounds

  // Stock Status Colors
  static const Color stockOkColor = successColor; // Green for stock > 10
  static const Color stockLowColor = warningColor; // Orange for stock 5-10
  static const Color stockCriticalColor = errorColor; // Red for stock < 5

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: MaterialColor(primaryColor.value, {
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor,
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor,
      }),
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: primaryBackground,
        error: errorColor,
        onPrimary: onPrimary,
        onSecondary: primaryText,
        onSurface: primaryText,
        onError: onPrimary,
      ),
      scaffoldBackgroundColor: primaryBackground,
      cardColor: cardBackground,
      
      // Typography optimized for 41-year-old user
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: AppConfig.headingFontSize,
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: AppConfig.subHeadingFontSize,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: AppConfig.bodyFontSize,
          fontWeight: FontWeight.normal,
          color: primaryText,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: AppConfig.bodyFontSize,
          fontWeight: FontWeight.normal,
          color: primaryText,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: AppConfig.buttonFontSize,
          fontWeight: FontWeight.w500,
          color: onPrimary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: AppConfig.captionFontSize,
          fontWeight: FontWeight.normal,
          color: secondaryText,
        ),
      ),
      
      // Button Themes - Large and accessible
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          minimumSize: const Size(AppConfig.buttonMinWidth, AppConfig.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.roboto(
            fontSize: AppConfig.buttonFontSize,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: AppConfig.subHeadingFontSize,
          fontWeight: FontWeight.w600,
          color: onPrimary,
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBackground,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.roboto(
          fontSize: AppConfig.bodyFontSize,
          color: primaryText,
        ),
        hintStyle: GoogleFonts.roboto(
          fontSize: AppConfig.bodyFontSize,
          color: secondaryText,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: AppConfig.subHeadingFontSize,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: AppConfig.bodyFontSize,
          color: primaryText,
        ),
      ),
    );
  }

  // Helper method to get stock status color
  static Color getStockStatusColor(int stock) {
    if (stock <= AppConfig.criticalStockThreshold) {
      return stockCriticalColor;
    } else if (stock <= AppConfig.lowStockThreshold) {
      return stockLowColor;
    } else {
      return stockOkColor;
    }
  }

  // Helper method to get stock status text
  static String getStockStatusText(int stock) {
    if (stock <= AppConfig.criticalStockThreshold) {
      return 'Nta biri muri stock'; // Out of stock
    } else if (stock <= AppConfig.lowStockThreshold) {
      return 'Stock iri hasi'; // Low stock
    } else {
      return 'Biri muri stock'; // In stock
    }
  }
}
