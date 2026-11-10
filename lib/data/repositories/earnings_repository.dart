import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earning_entry.dart';

final earningsRepositoryProvider =
    Provider<EarningsRepository>((ref) => EarningsRepository());

class EarningsRepository {
  final _col = FirebaseFirestore.instance.collection('earnings');

  /// Rider ki saari kamayi. "Aaj" ka hisaab app mein hota hai,
  /// taake Firestore index na banana paray.
  Stream<List<EarningEntry>> watchForRider(String uid) {
    return _col
        .where('riderId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(EarningEntry.fromDoc).toList());
  }
}