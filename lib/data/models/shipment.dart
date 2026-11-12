import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../services/pricing_service.dart';
import 'parcel_options.dart';

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
  final LatLng? pickupPoint;
  final LatLng? dropPoint;
  final PaymentPayer? payer;
  final ParcelCategory category;
  final ParcelSize size;
  final double weightKg;
  final bool fragile;
  final DeliverySpeed speed;
  final bool hasPhoto;
  final List<PriceLine> priceLines;

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
    this.pickupPoint,
    this.dropPoint,
    this.payer,
    this.category = ParcelCategory.other,
    this.size = ParcelSize.small,
    this.weightKg = 0,
    this.fragile = false,
    this.speed = DeliverySpeed.standard,
    this.hasPhoto = false,
    this.priceLines = const [],
  });

  static LatLng? _point(Map<String, dynamic> m) {
    final lat = m['lat'];
    final lng = m['lng'];
    if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
    return null;
  }

  static PaymentPayer? _payer(String? v) {
    for (final p in PaymentPayer.values) {
      if (p.value == v) return p;
    }
    return null;
  }

  static List<PriceLine> _lines(dynamic v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map)
          PriceLine(
            e['label'] as String? ?? '',
            (e['amount'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

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
      pickupPoint: _point(pickup),
      dropPoint: _point(drop),
      payer: _payer(d['payer'] as String?),
      category: ParcelCategory.values.firstWhere(
          (c) => c.value == d['category'],
          orElse: () => ParcelCategory.other),
      size: ParcelSize.values.firstWhere((s) => s.value == d['size'],
          orElse: () => ParcelSize.small),
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 0,
      fragile: d['fragile'] as bool? ?? false,
      speed: DeliverySpeed.values.firstWhere((s) => s.value == d['speed'],
          orElse: () => DeliverySpeed.standard),
      hasPhoto: d['hasPhoto'] as bool? ?? false,
      priceLines: _lines(d['priceLines']),
    );
  }
}