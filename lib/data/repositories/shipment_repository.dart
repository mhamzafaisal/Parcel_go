import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipment.dart';

final shipmentRepositoryProvider =
    Provider<ShipmentRepository>((ref) => ShipmentRepository());

class ShipmentRepository {
  final _col = FirebaseFirestore.instance.collection('shipments');

  /// Customer ki saari shipments, nayi pehle.
  /// Sorting app mein karte hain taake Firestore index na banana paray.
  Stream<List<Shipment>> watchCustomerShipments(String uid) {
    return _col.where('customerId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Shipment.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<Shipment?> findByTrackingId(String uid, String trackingId) async {
    final snap = await _col
        .where('customerId', isEqualTo: uid)
        .where('trackingId', isEqualTo: trackingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Shipment.fromDoc(snap.docs.first);
  }

  /// SIRF TESTING ke liye. Task 16 mein hata denge.
  Future<void> createSample(String uid) {
    final id = 'PG${1000 + Random().nextInt(9000)}';
    return _col.add({
      'customerId': uid,
      'riderId': null,
      'trackingId': id,
      'pickup': {'address': 'Peoples Colony, Faisalabad', 'lat': 31.4180, 'lng': 73.0790},
      'drop': {'address': 'D Ground, Faisalabad', 'lat': 31.4300, 'lng': 73.0900},
      'size': 'small',
      'weight': 1.5,
      'fragile': false,
      'price': 450,
      'status': 'created',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}