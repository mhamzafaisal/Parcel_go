import 'dart:math';

// 0, O, 1, I jaise ulajhne wale characters nahi hain
const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
final _rng = Random.secure();

/// Jaise PGK7M2X9Q
String generateTrackingId() =>
    'PG${List.generate(7, (_) => _chars[_rng.nextInt(_chars.length)]).join()}';

/// 6 digit, pehla digit 0 nahi
String generateOtp() => (100000 + _rng.nextInt(900000)).toString();