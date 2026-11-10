import 'package:cloud_firestore/cloud_firestore.dart';

class EarningEntry {
  final String jobId;
  final int amount;
  final DateTime deliveredAt;

  const EarningEntry({
    required this.jobId,
    required this.amount,
    required this.deliveredAt,
  });

  factory EarningEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['deliveredAt'];
    return EarningEntry(
      jobId: d['jobId'] as String? ?? doc.id,
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      // Naye likhe gaye document mein server time kuch pal null hota hai
      deliveredAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}