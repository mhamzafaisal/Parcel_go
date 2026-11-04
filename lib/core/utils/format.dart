import 'package:intl/intl.dart';

String formatRs(int amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}Rs ${NumberFormat('#,##0').format(amount.abs())}';
}

String formatEta(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}