class AppConstants {
  // Kinyarwanda Text Constants
  static const String appName = 'SHEBA BAR';
  static const String tagline = 'Sistema ya Gucunga Stock';

  // Navigation Labels
  static const String navDashboard = 'Ahabanza';
  static const String navStock = 'Gucunga Stock';
  static const String navProducts = 'Ibicuruzwa';
  static const String navReports = 'Raporo';
  static const String navSettings = 'Igenamigambi';

  // Login Screen
  static const String loginTitle = 'Injira';
  static const String username = 'Izina';
  static const String password = 'Ijambo ryibanga';
  static const String loginButton = 'INJIRA';
  static const String loginError = 'Izina cyangwa ijambo ryibanga ntibikwiye';

  // Dashboard
  static const String dashboardTitle = 'Ahabanza';
  static const String todayDate = 'Italiki';
  static const String itemsInStock = 'Ibicuruzwa muri Stock';
  static const String todayReport = 'Raporo y\'uyu munsi';
  static const String stockValue = 'Agaciro ka Stock';
  static const String damagedItems = 'Byongewe';
  static const String soldToday = 'Byagurishijwe';
  static const String lowStockAlert = 'Ibicuruzwa bike muri Stock';
  static const String inStock = 'biri muri stock';

  // Stock Management
  static const String stockManagementTitle = 'Gucunga Stock';
  static const String incoming = 'BYINJIYE';
  static const String sold = 'BYAGURISHIJWE';
  static const String damaged = 'BYONGEWE';
  static const String selectProduct = 'Hitamo Icyicuruzwa';
  static const String enterQuantity = 'Ingano';
  static const String confirm = 'EMEZA';
  static const String todayTransactions = 'Uyu Munsi';

  // Products
  static const String productsTitle = 'Ibicuruzwa';
  static const String search = 'Shakisha';
  static const String addProduct = 'Kongeraho';
  static const String productName = 'Izina ry\'icyicuruzwa';
  static const String category = 'Icategori';
  static const String price = 'Igiciro';
  static const String stock = 'Stock';
  static const String value = 'Agaciro';
  static const String save = 'BIKA';
  static const String cancel = 'HAGARIKA';
  static const String edit = 'HINDURA';
  static const String delete = 'KURAHO';

  // Reports
  static const String reportsTitle = 'Raporo';
  static const String selectPeriod = 'Hitamo Igihe';
  static const String today = 'Uyu munsi';
  static const String thisWeek = 'Iki cyumweru';
  static const String thisMonth = 'Uku kwezi';
  static const String customDate = 'Hitamo italiki';
  static const String viewReport = 'REBA RAPORO';
  static const String exportReport = 'TANGAZA';
  static const String summary = 'INCAMAKE';
  static const String totalSold = 'Byagurishijwe';
  static const String totalAmount = 'Amafaranga';
  static const String totalDamaged = 'Byongewe';
  static const String loss = 'Igihombo';

  // Settings
  static const String settingsTitle = 'Igenamigambi';
  static const String employees = 'Abakozi';
  static const String products = 'Ibicuruzwa';
  static const String backup = 'Backup';
  static const String userInfo = 'Amakuru y\'umukoresha';
  static const String logout = 'Gusohoka';
  static const String addEmployee = 'KONGERAHO UMUKOZI';

  // Messages
  static const String success = 'Byakozwe neza!';
  static const String error = 'Habayeho ikosa!';
  static const String confirmAction = 'Niwemeza?';
  static const String confirmDelete = 'Niwemeza ko ushaka gukuraho?';
  static const String confirmDamage = 'Niwemeza ko iki cyongewe?';
  static const String saved = 'Byanditswe neza!';
  static const String deleted = 'Byakuweho neza!';
  static const String lowStock = 'Stock iri hasi!';
  static const String outOfStock = 'Nta biri muri stock!';
  static const String noInternet = 'Nta murandasi!';
  static const String syncing = 'Birahuza...';
  static const String synced = 'Byahuye';
  static const String syncFailed = 'Ntibirahuze';

  // Stock Status
  static const String stockOk = 'Biri muri stock';
  static const String stockLow = 'Stock iri hasi';
  static const String stockCritical = 'Nta biri muri stock';

  // Time formats
  static const String timeFormat = 'HH:mm';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String currency = 'Frw';

  // Validation Messages
  static const String fieldRequired = 'Iki gikenewe';
  static const String invalidNumber = 'Umubare utakwiye';
  static const String invalidPrice = 'Igiciro kitakwiye';
  static const String productExists = 'Iki cyicuruzwa gihari';
  static const String insufficientStock = 'Stock ntihagije';
  static const String usernameExists = 'Iri zina rihari';

  // Product Categories (Display Names)
  static const Map<String, String> categoryNames = {
    'INZOGA_NINI': 'Inzoga Nini',
    'INZOGA_NTO': 'Inzoga Nto',
    'IBINYOBWA_BIDAFITE_ALCOHOL': 'Ibinyobwa bidafite Alcohol',
    'VINO': 'Vino',
    'SPIRITS': 'Spirits',
    'AMAZI': 'Amazi',
  };

  // Default Products (from PDF)
  static const List<Map<String, dynamic>> defaultProducts = [
    // Inzoga Nini
    {'name': 'AMSTEL', 'category': 'INZOGA_NINI', 'price': 1200.0, 'stock': 40},
    {'name': 'PRIMUS', 'category': 'INZOGA_NINI', 'price': 1400.0, 'stock': 9},
    {'name': 'HEINEKEN', 'category': 'INZOGA_NINI', 'price': 1400.0, 'stock': 21},
    {'name': 'TURBO', 'category': 'INZOGA_NINI', 'price': 1200.0, 'stock': 27},
    {'name': 'LEGEND', 'category': 'INZOGA_NINI', 'price': 1200.0, 'stock': 26},
    {'name': 'KNOWLESS', 'category': 'INZOGA_NINI', 'price': 1000.0, 'stock': 23},
    {'name': 'G.SKOL', 'category': 'INZOGA_NINI', 'price': 1500.0, 'stock': 21},
    {'name': 'G.LAGER', 'category': 'INZOGA_NINI', 'price': 1000.0, 'stock': 15},
    
    // Inzoga Nto
    {'name': 'P.MITZIG', 'category': 'INZOGA_NTO', 'price': 1000.0, 'stock': 25},
    {'name': 'G.MITZING', 'category': 'INZOGA_NTO', 'price': 1800.0, 'stock': 2},
    {'name': 'P.SKOL', 'category': 'INZOGA_NTO', 'price': 1000.0, 'stock': 23},
    {'name': 'P.LAGER', 'category': 'INZOGA_NTO', 'price': 800.0, 'stock': 4},
    
    // Spirits
    {'name': 'LABEL 9', 'category': 'SPIRITS', 'price': 40000.0, 'stock': 1},
    {'name': 'JAMESON', 'category': 'SPIRITS', 'price': 45000.0, 'stock': 1},
    {'name': 'G.KONYAGE', 'category': 'SPIRITS', 'price': 8000.0, 'stock': 2},
    {'name': 'H.KONYAGE', 'category': 'SPIRITS', 'price': 6000.0, 'stock': 2},
    {'name': 'S.KONYAGE', 'category': 'SPIRITS', 'price': 3500.0, 'stock': 2},
    
    // Vino
    {'name': 'RED WINE PICHE', 'category': 'VINO', 'price': 4000.0, 'stock': 1},
    {'name': 'SWET WINE', 'category': 'VINO', 'price': 4000.0, 'stock': 1},
    
    // Ibinyobwa bidafite Alcohol
    {'name': 'G.FANTA', 'category': 'IBINYOBWA_BIDAFITE_ALCOHOL', 'price': 1000.0, 'stock': 24},
    {'name': 'P.FANTA', 'category': 'IBINYOBWA_BIDAFITE_ALCOHOL', 'price': 700.0, 'stock': 18},
    {'name': 'MILINDA', 'category': 'IBINYOBWA_BIDAFITE_ALCOHOL', 'price': 1200.0, 'stock': 13},
    {'name': 'ENERGY', 'category': 'IBINYOBWA_BIDAFITE_ALCOHOL', 'price': 700.0, 'stock': 15},
    {'name': 'JUS', 'category': 'IBINYOBWA_BIDAFITE_ALCOHOL', 'price': 1000.0, 'stock': 3},
    
    // Amazi
    {'name': 'AMAZI MATO', 'category': 'AMAZI', 'price': 500.0, 'stock': 11},
    {'name': 'AMAZI MANINI', 'category': 'AMAZI', 'price': 1000.0, 'stock': 1},
  ];

  // Number formatting
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} $currency';
  }

  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
