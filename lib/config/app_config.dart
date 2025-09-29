class AppConfig {
  // App Information
  static const String appName = 'SHEBA BAR';
  static const String appVersion = '1.0.0';
  
  // Database Configuration
  static const String dbHost = 'localhost';
  static const int dbPort = 3306;
  static const String dbUser = 'root';
  static const String dbPassword = '';
  static const String dbName = 'shebabar';
  
  // Local Database
  static const String localDbName = 'shebabar_local.db';
  static const int localDbVersion = 1;
  
  // UI Configuration
  static const double buttonHeight = 60.0;
  static const double buttonMinWidth = 200.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  
  // Font Sizes (for 41-year-old user)
  static const double headingFontSize = 32.0;
  static const double subHeadingFontSize = 24.0;
  static const double bodyFontSize = 18.0;
  static const double buttonFontSize = 20.0;
  static const double captionFontSize = 14.0;
  
  // Auto-refresh intervals
  static const int dashboardRefreshSeconds = 30;
  static const int syncIntervalMinutes = 5;
  
  // Stock levels
  static const int lowStockThreshold = 5;
  static const int criticalStockThreshold = 2;
  
  // Session timeout (8 hours)
  static const int sessionTimeoutHours = 8;
}
