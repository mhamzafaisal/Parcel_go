import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String shipmentId;
  final String riderId;
  final int stars;
  final String comment;
  final DateTime createdAt;

  const Rating({
    required this.shipmentId,
    required this.riderId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory Rating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return Rating(
      shipmentId: d['shipmentId'] as String? ?? doc.id,
      riderId: d['riderId'] as String? ?? '',
      stars: (d['stars'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      // Naye likhe gaye document mein server time kuch pal null hota hai
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

/// Rider ka jama-shuda hisaab
class RiderStats {
  final int sum;
  final int count;
  const RiderStats({required this.sum, required this.count});

  static const empty = RiderStats(sum: 0, count: 0);

  double? get average => count == 0 ? null : sum / count;
}

/// "New" ya "4.5 (12)"
String ratingLabel(RiderStats s) =>
    s.count == 0 ? 'New' : '${s.average!.toStringAsFixed(1)} (${s.count})';

String starLabel(int stars) {
  switch (stars) {
    case 1:
      return 'Poor';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    case 4:
      return 'Very good';
    case 5:
      return 'Excellent';
    default:
      return '';
  }
}