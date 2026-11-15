import '../models/earning_entry.dart';

enum EarningsPeriod {
  today('Today'),
  week('This week'),
  month('This month'),
  all('All time');

  final String label;
  const EarningsPeriod(this.label);
}

/// Period shuru kab hota hai (hafta Monday se). "All time" ke liye null.
DateTime? periodStart(EarningsPeriod p, DateTime now) {
  switch (p) {
    case EarningsPeriod.today:
      return DateTime(now.year, now.month, now.day);
    case EarningsPeriod.week:
      return DateTime(now.year, now.month, now.day - (now.weekday - 1));
    case EarningsPeriod.month:
      return DateTime(now.year, now.month, 1);
    case EarningsPeriod.all:
      return null;
  }
}

class PeriodSummary {
  final int earned;
  final int cash;
  final int platformFee;
  final int count;

  const PeriodSummary({
    required this.earned,
    required this.cash,
    required this.platformFee,
    required this.count,
  });

  int get average => count == 0 ? 0 : (earned / count).round();
}

List<EarningEntry> entriesInPeriod(
  List<EarningEntry> entries,
  EarningsPeriod period,
  DateTime now,
) {
  final start = periodStart(period, now);
  if (start == null) return List.of(entries);
  return entries.where((e) => !e.deliveredAt.isBefore(start)).toList();
}

PeriodSummary summarizePeriod(
  List<EarningEntry> entries,
  EarningsPeriod period,
  DateTime now,
) {
  var earned = 0;
  var cash = 0;
  var fee = 0;
  final inPeriod = entriesInPeriod(entries, period, now);
  for (final e in inPeriod) {
    earned += e.amount;
    cash += e.cash;
    fee += e.platformFee;
  }
  return PeriodSummary(
    earned: earned,
    cash: cash,
    platformFee: fee,
    count: inPeriod.length,
  );
}

class DayTotal {
  final DateTime day;
  final int amount;
  const DayTotal(this.day, this.amount);
}

/// Pichle [days] din ki kamayi, purana pehle, aakhri entry aaj ki
List<DayTotal> dailyTotals(
  List<EarningEntry> entries,
  DateTime now, {
  int days = 7,
}) {
  final result = <DayTotal>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day - i);
    var sum = 0;
    for (final e in entries) {
      final t = e.deliveredAt;
      if (t.year == day.year && t.month == day.month && t.day == day.day) {
        sum += e.amount;
      }
    }
    result.add(DayTotal(day, sum));
  }
  return result;
}
