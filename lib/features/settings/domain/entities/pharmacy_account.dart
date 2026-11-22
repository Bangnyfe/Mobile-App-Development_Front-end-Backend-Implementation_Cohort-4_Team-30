import 'package:equatable/equatable.dart';

import '../../../../core/domain/user_role.dart';

/// What the Settings screens need to know about the pharmacy and who is
/// signed in.
///
/// These are kept small on purpose. When the shared data layer (pharmacy,
/// users, categories) and auth are merged, the repository maps those
/// documents into these, so the Settings UI doesn't change.
class PharmacyAccount extends Equatable {
  const PharmacyAccount({
    required this.pharmacy,
    required this.user,
    required this.staff,
    required this.categories,
  });

  final Pharmacy pharmacy;

  /// The person signed in on this phone.
  final StaffMember user;

  /// Everyone with access to this pharmacy, including [user].
  final List<StaffMember> staff;

  final List<ProductCategory> categories;

  @override
  List<Object?> get props => [pharmacy, user, staff, categories];
}

class Pharmacy extends Equatable {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.district,
    required this.city,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String district;
  final String city;
  final String? phone;
  final String? address;

  /// e.g. "Nyarugenge, Kigali". Leaves out whichever part is empty.
  String get location =>
      [district, city].where((part) => part.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [id, name, district, city, phone, address];
}

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  String get firstName => name.split(' ').first;

  bool get isOwner => role == UserRole.owner;

  @override
  List<Object?> get props => [id, name, email, role];
}

class ProductCategory extends Equatable {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.productCount,
  });

  final String id;
  final String name;
  final int productCount;

  @override
  List<Object?> get props => [id, name, productCount];
}
