import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipment.dart';

class ShipmentEvent {
  final ShipmentStatus status;
  final DateTime at;
  const ShipmentEvent({required this.status, required this.at});

  factory ShipmentEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['at'];
    return ShipmentEvent(
      status: ShipmentStatus.fromValue(d['status'] as String?),
      // Naye likhe gaye document mein server time kuch pal null hota hai
      at: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}