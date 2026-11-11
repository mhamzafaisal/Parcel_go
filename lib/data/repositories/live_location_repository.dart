import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final liveLocationRepositoryProvider =
    Provider<LiveLocationRepository>((ref) => LiveLocationRepository());

class LiveLocation {
  final LatLng point;
  final DateTime at;
  const LiveLocation({required this.point, required this.at});
}

class LiveLocationRepository {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String shipmentId) => _db
      .collection('shipments')
      .doc(shipmentId)
      .collection('live')
      .doc('rider');

  /// Rider ki taaza location (har baar usi ek document par likhta hai)
  Future<void> publish(
    String shipmentId, {
    required double lat,
    required double lng,
  }) {
    return _doc(shipmentId).set({
      'lat': lat,
      'lng': lng,
      'at': FieldValue.serverTimestamp(),
    });
  }

  Stream<LiveLocation?> watch(String shipmentId) {
    return _doc(shipmentId).snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return null;
      final lat = d['lat'];
      final lng = d['lng'];
      if (lat is! num || lng is! num) return null;
      final at = d['at'];
      return LiveLocation(
        point: LatLng(lat.toDouble(), lng.toDouble()),
        // Naye likhe gaye document mein server time kuch pal null hota hai
        at: at is Timestamp ? at.toDate() : DateTime.now(),
      );
    });
  }
}