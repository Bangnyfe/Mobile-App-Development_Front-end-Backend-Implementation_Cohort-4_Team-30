import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/sale.dart';

/// Turns a `pharmacies/{id}/sales/{saleId}` document into a [Sale].
///
/// Sale documents are written by checkout, but this is forgiving about
/// missing or oddly typed fields so one bad document can't break the whole
/// history. [now] is used if `createdAt` hasn't been set by the server yet.
Sale saleFromFirestore(
  String id,
  Map<String, dynamic> data, {
  DateTime? now,
}) {
  final total = _int(data['total']);
  final rawItems = data['items'];

  return Sale(
    id: id,
    receiptNo: _string(data['receiptNo']),
    createdAt: _dateTime(data['createdAt']) ?? now ?? DateTime.now(),
    soldBy: _string(data['soldBy']),
    soldByName: data['soldByName'] as String?,
    paymentMethod: _string(data['paymentMethod'], fallback: 'Unknown'),
    total: total,
    cashReceived: data['cashReceived'] == null
        ? total
        : _int(data['cashReceived']),
    change: _int(data['change']),
    lines: [
      if (rawItems is List)
        for (final item in rawItems)
          if (item is Map) _saleLine(Map<String, dynamic>.from(item)),
    ],
  );
}

SaleLine _saleLine(Map<String, dynamic> data) => SaleLine(
  productId: _string(data['productId']),
  batchId: _string(data['batchId']),
  productName: _string(data['productName'], fallback: 'Unknown product'),
  quantity: _int(data['quantity']),
  unitPrice: _int(data['unitPrice']),
);

String _string(Object? value, {String fallback = ''}) => switch (value) {
  final String text => text,
  final num number => number.toString(),
  _ => fallback,
};

int _int(Object? value) => value is num ? value.toInt() : 0;

DateTime? _dateTime(Object? value) => switch (value) {
  final Timestamp timestamp => timestamp.toDate(),
  final DateTime dateTime => dateTime,
  _ => null,
};
