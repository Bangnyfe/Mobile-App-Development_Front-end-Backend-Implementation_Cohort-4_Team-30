/// Every route path in the app, kept in one place so features never
/// hard-code location strings.
abstract final class RoutePaths {
  // Bottom navigation tabs, in tab order.
  static const home = '/home';
  static const sell = '/sell';
  static const stock = '/stock';
  static const reports = '/reports';
  static const settings = '/settings';

  // Home subpages.
  static const salesHistory = '$home/sales';
  static String saleDetails(String saleId) => '$salesHistory/$saleId';
  static const notifications = '$home/notifications';

  // Reports subpages. Sales history is reachable from Home too; these
  // copies keep the Reports tab selected when it's opened from here.
  static const reportsSalesHistory = '$reports/sales';
  static String reportsSaleDetails(String saleId) =>
      '$reportsSalesHistory/$saleId';
  static const inventoryReport = '$reports/inventory';
  static const expiryWasteReport = '$reports/expiry-waste';

  // Settings subpages.
  static const pharmacyProfile = '$settings/pharmacy';
  static const staff = '$settings/staff';
  static const categories = '$settings/categories';
}
