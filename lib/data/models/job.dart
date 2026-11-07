import 'package:cloud_firestore/cloud_firestore.dart';
import 'parcel_options.dart';
import 'place_result.dart';

class Job {
  final String id;
  final String trackingId;
  final String customerId;
  final PlaceResult pickup;
  final PlaceResult drop;
  final ParcelCategory category;
  final ParcelSize size;
  final double weightKg;
  final bool fragile;
  final DeliverySpeed speed;
  final int price;
  final int riderEarning;
  final double roadKm;
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.trackingId,
    required this.customerId,
    required this.pickup,
    required this.drop,
    required this.category,
    required this.size,
    required this.weightKg,
    required this.fragile,
    required this.speed,
    required this.price,
    required this.riderEarning,
    required this.roadKm,
    required this.createdAt,
  });

  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return Job(
      id: doc.id,
      trackingId: d['trackingId'] as String? ?? doc.id,
      customerId: d['customerId'] as String? ?? '',
      pickup: PlaceResult.fromMap(d['pickup'] as Map<String, dynamic>),
      drop: PlaceResult.fromMap(d['drop'] as Map<String, dynamic>),
      category: ParcelCategory.values.firstWhere(
          (c) => c.value == d['category'],
          orElse: () => ParcelCategory.other),
      size: ParcelSize.values.firstWhere((s) => s.value == d['size'],
          orElse: () => ParcelSize.small),
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 0,
      fragile: d['fragile'] as bool? ?? false,
      speed: DeliverySpeed.values.firstWhere((s) => s.value == d['speed'],
          orElse: () => DeliverySpeed.standard),
      price: (d['price'] as num?)?.toInt() ?? 0,
      riderEarning: (d['riderEarning'] as num?)?.toInt() ?? 0,
      roadKm: (d['roadKm'] as num?)?.toDouble() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}