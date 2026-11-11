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

/// "just now", "30 s ago", "2 min ago", "3 h ago"
String timeAgo(DateTime t, DateTime now) {
  final s = now.difference(t).inSeconds;
  if (s < 10) return 'just now';
  if (s < 60) return '$s s ago';
  final m = s ~/ 60;
  if (m < 60) return '$m min ago';
  return '${m ~/ 60} h ago';
}