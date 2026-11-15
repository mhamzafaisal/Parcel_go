import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/pricing_service.dart';

class EarningEntry {
  final String jobId;

  /// Rider ka apna hissa
  final int amount;

  /// Customer se li gayi cash. Purani entries mein nahi hota.
  final int? price;

  final DateTime deliveredAt;

  const EarningEntry({
    required this.jobId,
    required this.amount,
    this.price,
    required this.deliveredAt,
  });

  /// Rider ne customer se kitni cash li
  int get cash => price ?? (amount / PricingService.riderShare).round();

  /// Platform ka hissa
  int get platformFee => cash - amount;

  factory EarningEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['deliveredAt'];
    return EarningEntry(
      jobId: d['jobId'] as String? ?? doc.id,
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      price: (d['price'] as num?)?.toInt(),
      // Naye likhe gaye document mein server time kuch pal null hota hai
      deliveredAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
