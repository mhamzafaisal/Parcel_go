import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/earning_entry.dart';
import '../../../data/repositories/earnings_repository.dart';
import '../../auth/auth_providers.dart';

class EarningsSummary {
  final int amount;
  final int deliveries;
  const EarningsSummary({required this.amount, required this.deliveries});

  static const zero = EarningsSummary(amount: 0, deliveries: 0);
}

/// Aaj (apne waqt ke hisaab se) ki kamayi aur deliveries
EarningsSummary summarizeToday(List<EarningEntry> entries, DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  var amount = 0;
  var count = 0;
  for (final e in entries) {
    if (!e.deliveredAt.isBefore(start)) {
      amount += e.amount;
      count++;
    }
  }
  return EarningsSummary(amount: amount, deliveries: count);
}

final riderEarningsProvider = StreamProvider<List<EarningEntry>>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const <EarningEntry>[]);
  return ref.watch(earningsRepositoryProvider).watchForRider(uid);
});

final todayEarningsProvider = Provider<AsyncValue<EarningsSummary>>((ref) {
  return ref
      .watch(riderEarningsProvider)
      .whenData((entries) => summarizeToday(entries, DateTime.now()));
});