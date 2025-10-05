enum Permission {
  manageUsers,
  manageProducts,
  recordStock,
  viewDashboard,
  viewDetailedReports,
  exportReports,
}

extension PermissionExtension on Permission {
  String get displayName {
    switch (this) {
      case Permission.manageUsers:
        return 'Gucunga abakoresha';
      case Permission.manageProducts:
        return 'Gucunga ibicuruzwa';
      case Permission.recordStock:
        return 'Kwandika stock';
      case Permission.viewDashboard:
        return 'Kureba dashboard';
      case Permission.viewDetailedReports:
        return 'Kureba raporo zirambuye';
      case Permission.exportReports:
        return 'Gusohora raporo';
    }
  }

  String get description {
    switch (this) {
      case Permission.manageUsers:
        return 'Kongeramo, guhindura no gukuraho abakoresha';
      case Permission.manageProducts:
        return 'Kongeramo, guhindura no gukuraho ibicuruzwa';
      case Permission.recordStock:
        return 'Kwandika stock yinjiye, igurishijwe n\'iyongewe';
      case Permission.viewDashboard:
        return 'Kureba dashboard n\'imibare y\'ingenzi';
      case Permission.viewDetailedReports:
        return 'Kureba raporo zirambuye z\'ubucuruzi';
      case Permission.exportReports:
        return 'Gusohora raporo mu buryo bw\'PDF cyangwa Excel';
    }
  }
}
