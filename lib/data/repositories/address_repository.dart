import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place_result.dart';
import '../models/saved_address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(),
);

class AddressRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('addresses');

  /// Purane pehle
  Stream<List<SavedAddress>> watch(String uid) {
    return _col(uid).snapshots().map((snap) {
      final list = snap.docs.map(SavedAddress.fromDoc).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> add(
    String uid, {
    required String label,
    required PlaceResult place,
  }) {
    return _col(uid).add({
      'label': label,
      'address': place.address,
      'lat': place.latitude,
      'lng': place.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();
}
