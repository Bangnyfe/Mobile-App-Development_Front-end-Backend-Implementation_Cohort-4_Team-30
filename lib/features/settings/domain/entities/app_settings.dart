import 'package:equatable/equatable.dart';

/// The user's preferences, saved on this device only.
///
/// They change what the app shows (which products count as low stock, how
/// early batches are flagged as expiring) but not the shared Firestore data,
/// so each phone can have its own.
class AppSettings extends Equatable {
  const AppSettings({
    this.lowStockThreshold = defaultLowStockThreshold,
    this.expiryAlertDays = defaultExpiryAlertDays,
    this.pushNotificationsEnabled = true,
  });

  static const defaultLowStockThreshold = 20;
  static const defaultExpiryAlertDays = 90;

  /// Allowed ranges, so a typo can't hide every alert (0) or flag every
  /// product (a huge number).
  static const minLowStockThreshold = 1;
  static const maxLowStockThreshold = 1000;
  static const minExpiryAlertDays = 1;
  static const maxExpiryAlertDays = 365;

  /// Default reorder level for products that don't have their own. A
  /// product is low on stock when its total units across all batches are
  /// at or below its reorder level.
  final int lowStockThreshold;

  /// A batch is "expiring soon" when it expires within this many days.
  final int expiryAlertDays;

  final bool pushNotificationsEnabled;

  static bool isValidLowStockThreshold(int value) =>
      value >= minLowStockThreshold && value <= maxLowStockThreshold;

  static bool isValidExpiryAlertDays(int value) =>
      value >= minExpiryAlertDays && value <= maxExpiryAlertDays;

  AppSettings copyWith({
    int? lowStockThreshold,
    int? expiryAlertDays,
    bool? pushNotificationsEnabled,
  }) => AppSettings(
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    expiryAlertDays: expiryAlertDays ?? this.expiryAlertDays,
    pushNotificationsEnabled:
        pushNotificationsEnabled ?? this.pushNotificationsEnabled,
  );

  @override
  List<Object?> get props => [
    lowStockThreshold,
    expiryAlertDays,
    pushNotificationsEnabled,
  ];
}
