import 'package:cloud_firestore/cloud_firestore.dart';

enum ShipmentStatus {
  created('created', 'Created'),
  assigned('assigned', 'Rider assigned'),
  pickedUp('picked_up', 'Picked up'),
  inTransit('in_transit', 'In transit'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const ShipmentStatus(this.value, this.label);

  static ShipmentStatus fromValue(String? v) => ShipmentStatus.values
      .firstWhere((s) => s.value == v, orElse: () => ShipmentStatus.created);
}

class Shipment {
  final String id;
  final String trackingId;
  final String customerId;
  final String? riderId;
  final String pickupAddress;
  final String dropAddress;
  final ShipmentStatus status;
  final double price;
  final DateTime createdAt;
  final String receiverName;
  final String receiverPhone;
  final String notes;

  const Shipment({
    required this.id,
    required this.trackingId,
    required this.customerId,
    required this.riderId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.status,
    required this.price,
    required this.createdAt,
    this.receiverName = '',
    this.receiverPhone = '',
    this.notes = '',
  });

  factory Shipment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final pickup = d['pickup'] as Map<String, dynamic>? ?? {};
    final drop = d['drop'] as Map<String, dynamic>? ?? {};
    final ts = d['createdAt'];
    return Shipment(
      id: doc.id,
      trackingId: d['trackingId'] as String? ?? doc.id,
      customerId: d['customerId'] as String? ?? '',
      riderId: d['riderId'] as String?,
      pickupAddress: pickup['address'] as String? ?? '-',
      dropAddress: drop['address'] as String? ?? '-',
      status: ShipmentStatus.fromValue(d['status'] as String?),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      // Naye likhe gaye document mein server time kuch pal null hota hai
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      receiverName: d['receiverName'] as String? ?? '',
      receiverPhone: d['receiverPhone'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
    );
  }
}