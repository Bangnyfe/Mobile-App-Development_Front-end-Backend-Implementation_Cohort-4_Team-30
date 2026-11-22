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

  // Sell subpages. Opened above the tabs (no bottom bar), as in the Figma
  // flow; back returns to Sell. Product found and Receipt need their data
  // passed as `extra`.
  static const sellProduct = '$sell/product';
  static const sellCart = '$sell/cart';
  static const sellCheckout = '$sell/checkout';
  static const sellReceipt = '$sell/receipt';

  // Stock subpages, inside the Stock tab.
  static String stockProduct(String productId) => '$stock/products/$productId';

  // Reports subpages. Sales history is reachable from Home too; these
  // copies keep the Reports tab selected when it's opened from here.
  static const reportsSalesHistory = '$reports/sales';
  static String reportsSaleDetails(String saleId) =>
      '$reportsSalesHistory/$saleId';
  static const inventoryReport = '$reports/inventory';
  static const expiryWasteReport = '$reports/expiry-waste';

  // Full-screen flows opened above the tabs (no bottom bar).
  static const removeStock = '/remove-stock';

  /// Add stock starts with a scan; [addStockFor] skips it for a product
  /// chosen on Product details.
  static const addStock = '/add-stock';
  static String addStockFor(String productId) =>
      Uri(path: addStock, queryParameters: {'productId': productId}).toString();

  /// Takes the barcode to fill in as `extra`, and closes with the new
  /// product.
  static const registerProduct = '/register-product';

  /// Remove stock with the batch already chosen and Expired suggested,
  /// as opened from an expiry notification.
  static String removeExpiredBatch({
    required String productId,
    required String batchId,
  }) => Uri(
    path: removeStock,
    queryParameters: {
      'productId': productId,
      'batchId': batchId,
      'reason': 'expired',
    },
  ).toString();

  // Settings subpages.
  static const pharmacyProfile = '$settings/pharmacy';
  static const staff = '$settings/staff';
  static const categories = '$settings/categories';
}
