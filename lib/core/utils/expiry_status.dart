/// Where a batch stands relative to its expiry date.
enum ExpiryStatus { expired, expiringSoon, inDate }

/// Whole days from [today] until [expiryDate], comparing calendar days only.
///
/// Times of day are ignored, so a batch saved as "1 Dec 15:30" counts the
/// same as "1 Dec 00:00". The days are compared in UTC so a daylight-saving
/// change can't make a day 23 or 25 hours long. Negative means expired.
int daysUntilExpiry(DateTime expiryDate, {required DateTime today}) {
  final expiry = DateTime.utc(
    expiryDate.year,
    expiryDate.month,
    expiryDate.day,
  );
  final now = DateTime.utc(today.year, today.month, today.day);
  return expiry.difference(now).inDays;
}

/// Classifies a batch. A batch expiring today is still sellable, so it is
/// "expiring soon", not expired. [alertDays] is the expiry alert period
/// from Settings (90 days by default).
ExpiryStatus expiryStatusFor(
  DateTime expiryDate, {
  required DateTime today,
  required int alertDays,
}) {
  final days = daysUntilExpiry(expiryDate, today: today);
  if (days < 0) return ExpiryStatus.expired;
  if (days <= alertDays) return ExpiryStatus.expiringSoon;
  return ExpiryStatus.inDate;
}

/// Text for a batch's status chip: "Expired", "Expires today", "1 day",
/// "19 days" or "In date".
String expiryLabel(
  DateTime expiryDate, {
  required DateTime today,
  required int alertDays,
}) {
  final days = daysUntilExpiry(expiryDate, today: today);
  return switch (expiryStatusFor(
    expiryDate,
    today: today,
    alertDays: alertDays,
  )) {
    ExpiryStatus.expired => 'Expired',
    ExpiryStatus.inDate => 'In date',
    ExpiryStatus.expiringSoon when days == 0 => 'Expires today',
    ExpiryStatus.expiringSoon when days == 1 => '1 day',
    ExpiryStatus.expiringSoon => '$days days',
  };
}
