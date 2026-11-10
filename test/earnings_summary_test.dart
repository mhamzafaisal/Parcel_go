import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/earning_entry.dart';
import 'package:parcel_go/features/rider/home/rider_providers.dart';

EarningEntry entry(int amount, DateTime at) =>
    EarningEntry(jobId: 'j$amount', amount: amount, deliveredAt: at);

void main() {
  final now = DateTime(2026, 11, 8, 15, 30);

  test('adds up only today\'s deliveries', () {
    final summary = summarizeToday([
      entry(232, DateTime(2026, 11, 8, 9, 0)),
      entry(120, DateTime(2026, 11, 8, 14, 0)),
      entry(400, DateTime(2026, 11, 7, 23, 59)),
    ], now);
    expect(summary.amount, 352);
    expect(summary.deliveries, 2);
  });

  test('no deliveries gives zero', () {
    final summary = summarizeToday([], now);
    expect(summary.amount, 0);
    expect(summary.deliveries, 0);
  });
}