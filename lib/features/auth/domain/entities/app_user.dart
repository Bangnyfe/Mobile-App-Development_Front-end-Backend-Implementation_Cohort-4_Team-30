import 'package:equatable/equatable.dart';

import '../../../../core/domain/user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.emailVerified,
    this.role,
    this.pharmacyId,
  });

  final String uid;
  final String email;
  final String name;

  final bool emailVerified;

  final UserRole? role;
  final String? pharmacyId;

  /// False until a `users/{uid}` document links the account to a pharmacy.
  bool get hasPharmacy => pharmacyId != null;

  bool get isOwner => role == UserRole.owner;

  AppUser copyWith({bool? emailVerified}) => AppUser(
    uid: uid,
    email: email,
    name: name,
    emailVerified: emailVerified ?? this.emailVerified,
    role: role,
    pharmacyId: pharmacyId,
  );

  @override
  List<Object?> get props => [
    uid,
    email,
    name,
    emailVerified,
    role,
    pharmacyId,
  ];
}
