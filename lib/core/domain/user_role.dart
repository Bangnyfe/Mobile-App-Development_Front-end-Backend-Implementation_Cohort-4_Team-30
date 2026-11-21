/// A user's role in their pharmacy, stored on `users/{uid}.role`.
///
/// Shared by auth (who is signed in) and Settings (who works here), so the
/// whole app agrees on one set of roles. Owners manage prices, reorder
/// levels, deletions and users. Pharmacists sell and manage stock.
enum UserRole {
  owner('Owner'),
  pharmacist('Pharmacist');

  const UserRole(this.label);

  /// Shown on screen, e.g. "Owner".
  final String label;

  /// Reads the stored role. Returns null for a missing or unknown value,
  /// so a typo in the database never gives someone a role by accident.
  static UserRole? fromName(String? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return null;
  }
}
