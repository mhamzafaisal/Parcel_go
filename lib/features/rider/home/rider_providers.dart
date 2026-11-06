import 'package:flutter_riverpod/flutter_riverpod.dart';

class EarningsSummary {
  final int amount;
  final int deliveries;
  const EarningsSummary({required this.amount, required this.deliveries});

  static const zero = EarningsSummary(amount: 0, deliveries: 0);
}

/// Abhi hamesha zero. Task 27 mein asli deliveries se bharega.
/// StreamProvider isliye hai ke screen ka code baad mein na badalna paray.
final todayEarningsProvider = StreamProvider<EarningsSummary>((ref) {
  return Stream.value(EarningsSummary.zero);
});