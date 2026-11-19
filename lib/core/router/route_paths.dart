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

  // Settings subpages.
  static const pharmacyProfile = '$settings/pharmacy';
  static const staff = '$settings/staff';
  static const categories = '$settings/categories';
}
