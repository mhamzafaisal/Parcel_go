import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';

final ratingRepositoryProvider =
    Provider<RatingRepository>((ref) => RatingRepository());

class RatingRepository {
  final _db = FirebaseFirestore.instance;

  /// Is shipment ki rating (null agar abhi nahi di)
  Stream<Rating?> watchRating(String shipmentId) {
    return _db
        .collection('ratings')
        .doc(shipmentId)
        .snapshots()
        .map((doc) => doc.exists ? Rating.fromDoc(doc) : null);
  }

  /// Rating aur rider ka hisaab ek hi batch mein. Rules dono ko milati hain.
  Future<void> submitRating({
    required String shipmentId,
    required String riderId,
    required String customerId,
    required int stars,
    required String comment,
  }) {
    final batch = _db.batch();
    batch.set(_db.collection('ratings').doc(shipmentId), {
      'shipmentId': shipmentId,
      'riderId': riderId,
      'customerId': customerId,
      'stars': stars,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.collection('riderStats').doc(riderId),
      {
        'ratingSum': FieldValue.increment(stars),
        'ratingCount': FieldValue.increment(1),
        'lastRatingId': shipmentId,
      },
      SetOptions(merge: true),
    );
    return batch.commit();
  }

  Stream<RiderStats> watchRiderStats(String riderId) {
    return _db.collection('riderStats').doc(riderId).snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return RiderStats.empty;
      return RiderStats(
        sum: (d['ratingSum'] as num?)?.toInt() ?? 0,
        count: (d['ratingCount'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Rider ki saari reviews, nayi pehle (sorting app mein, index ki zaroorat nahi)
  Stream<List<Rating>> watchRiderRatings(String riderId) {
    return _db
        .collection('ratings')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Rating.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}