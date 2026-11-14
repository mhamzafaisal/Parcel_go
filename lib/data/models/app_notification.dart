import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipment.dart';

class AppNotification {
  final String id;
  final String kind; // assigned, picked_up, in_transit, delivered, rating
  final String title;
  final String body;
  final String shipmentId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.shipmentId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return AppNotification(
      id: doc.id,
      kind: d['kind'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      shipmentId: d['shipmentId'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      // Naye likhe gaye document mein server time kuch pal null hota hai
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

// NOTE: Ye lafz Firestore rules ke lafzon se bilkul milte hone chahiye.
String statusNotificationTitle(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.assigned:
      return 'Rider assigned';
    case ShipmentStatus.pickedUp:
      return 'Parcel picked up';
    case ShipmentStatus.inTransit:
      return 'Parcel on the way';
    case ShipmentStatus.delivered:
      return 'Parcel delivered';
    default:
      return '';
  }
}

String statusNotificationId(String shipmentId, ShipmentStatus s) =>
    '${shipmentId}_${s.value}';

/// Customer ke liye: shipment ka status badla
Map<String, dynamic> statusNotificationData({
  required String userId,
  required String shipmentId,
  required ShipmentStatus status,
}) =>
    {
      'userId': userId,
      'kind': status.value,
      'title': statusNotificationTitle(status),
      'body': 'Tracking ID $shipmentId',
      'shipmentId': shipmentId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

String ratingNotificationId(String shipmentId) => '${shipmentId}_rating';

/// Rider ke liye: customer ne rating di
Map<String, dynamic> ratingNotificationData({
  required String userId,
  required String shipmentId,
}) =>
    {
      'userId': userId,
      'kind': 'rating',
      'title': 'New rating',
      'body': 'You received a new rating',
      'shipmentId': shipmentId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };