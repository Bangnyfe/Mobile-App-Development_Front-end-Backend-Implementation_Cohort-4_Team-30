import 'package:cloud_firestore/cloud_firestore.dart';

/// Forgiving readers shared by the inventory models' `fromMap`.
///
/// A field typed by hand in the Firebase console can come back as a double
/// or be missing, so one odd document never breaks a whole list.

String readString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

/// Whole RWF and unit counts are stored as `int`; a stray double is rounded
/// down rather than rejected.
int readInt(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;

int? readNullableInt(Object? value) => value is num ? value.toInt() : null;

/// Null while a server timestamp is still pending on this phone.
DateTime? readDate(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime date => date,
  _ => null,
};

Timestamp? writeDate(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
