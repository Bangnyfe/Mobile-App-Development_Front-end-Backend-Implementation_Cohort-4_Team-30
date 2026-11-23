import 'package:equatable/equatable.dart';

/// The pharmacy details typed on Register, kept until the email is
/// verified.
///
/// The pharmacy isn't created at registration: an invited pharmacist who
/// signs up with email must first get the chance to join their pharmacy
/// instead. The setup step after verification is pre-filled from this.
class PharmacyDraft extends Equatable {
  const PharmacyDraft({
    required this.name,
    required this.district,
    required this.city,
  });

  final String name;
  final String district;
  final String city;

  @override
  List<Object?> get props => [name, district, city];
}
