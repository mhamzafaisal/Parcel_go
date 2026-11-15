import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/earning_entry.dart';
import 'package:parcel_go/data/services/earnings_summary.dart';

void main() {
  // Budh, 11 Nov 2026
  final now = DateTime(2026, 11, 11, 15, 0);

  EarningEntry e(int amount, int price, DateTime at) => EarningEntry(
    jobId: 'j$amount',
    amount: amount,
    price: price,
    deliveredAt: at,
  );

  final entries = [
    e(232, 290, DateTime(2026, 11, 11, 9, 0)), // aaj
    e(120, 150, DateTime(2026, 11, 10, 18, 0)), // kal (Mangal)
    e(400, 500, DateTime(2026, 11, 8, 12, 0)), // pichla Itwar
    e(100, 125, DateTime(2026, 10, 31, 20, 0)), // pichla mahina
  ];

  test('period start dates (week starts on Monday)', () {
    expect(periodStart(EarningsPeriod.today, now), DateTime(2026, 11, 11));
    expect(periodStart(EarningsPeriod.week, now), DateTime(2026, 11, 9));
    expect(periodStart(EarningsPeriod.month, now), DateTime(2026, 11, 1));
    expect(periodStart(EarningsPeriod.all, now), isNull);
  });

  test('totals per period', () {
    final today = summarizePeriod(entries, EarningsPeriod.today, now);
    expect(today.earned, 232);
    expect(today.count, 1);

    final week = summarizePeriod(entries, EarningsPeriod.week, now);
    expect(week.earned, 352);
    expect(week.cash, 440);
    expect(week.platformFee, 88);
    expect(week.count, 2);

    final month = summarizePeriod(entries, EarningsPeriod.month, now);
    expect(month.earned, 752);

    final all = summarizePeriod(entries, EarningsPeriod.all, now);
    expect(all.earned, 852);
    expect(all.count, 4);
    expect(all.average, 213);
  });

  test('old entries without a price estimate the cash from the share', () {
    final old = EarningEntry(
      jobId: 'old',
      amount: 232,
      deliveredAt: DateTime(2026, 11, 11),
    );
    expect(old.cash, 290);
    expect(old.platformFee, 58);
  });

  test('last 7 days totals end with today', () {
    final days = dailyTotals(entries, now);
    expect(days.length, 7);
    expect(days.last.amount, 232); // aaj
    expect(days[5].amount, 120); // kal
    expect(days[3].amount, 400); // 8 Nov
    expect(days.first.amount, 0);
  });
}
