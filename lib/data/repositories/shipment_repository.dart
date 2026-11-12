import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/ids.dart';
import '../models/parcel_options.dart';
import '../models/place_result.dart';
import '../models/shipment.dart';
import '../services/pricing_service.dart';
import '../models/shipment_event.dart';

final shipmentRepositoryProvider =
    Provider<ShipmentRepository>((ref) => ShipmentRepository());

class BookingResult {
  final String trackingId;
  final String otp;
  const BookingResult({required this.trackingId, required this.otp});
}

class ShipmentRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('shipments');

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

  Stream<Shipment?> watchShipment(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Shipment.fromDoc(doc) : null);
  }
    /// Timeline ke events, purane pehle
  Stream<List<ShipmentEvent>> watchEvents(String id) {
    return _col
        .doc(id)
        .collection('events')
        .orderBy('at')
        .snapshots()
        .map((snap) => snap.docs.map(ShipmentEvent.fromDoc).toList());
  }

  /// Delivery code (sirf customer padh sakta hai)
  Stream<String?> watchOtp(String id) {
    return _col
        .doc(id)
        .collection('secret')
        .doc('otp')
        .snapshots()
        .map((doc) => doc.data()?['code'] as String?);
  }

  /// photoId: 'main' (parcel ki photo) ya 'proof' (delivery ka saboot)
  Future<Uint8List?> getPhoto(String id, String photoId) async {
    final doc = await _col.doc(id).collection('photos').doc(photoId).get();
    final data = doc.data()?['data'];
    return data is Blob ? data.bytes : null;
  }

  /// Shipment, job, pehla event, OTP aur (agar ho) photo ek hi batch mein
  /// save hote hain: ya sab ho jata hai, ya kuch bhi nahi.
  Future<BookingResult> createShipment({
    required String uid,
    required PlaceResult pickup,
    required PlaceResult drop,
    required ParcelCategory category,
    required ParcelSize size,
    required double weightKg,
    required bool fragile,
    required DeliverySpeed speed,
    required String receiverName,
    required String receiverPhone,
    required String notes,
    required Uint8List? photo,
    required PriceBreakdown price,
    required PaymentPayer payer,
  }) async {
    final otp = generateOtp();
    FirebaseException? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      final trackingId = generateTrackingId();
      final ref = _col.doc(trackingId);
      final batch = _db.batch();

      batch.set(ref, {
        'trackingId': trackingId,
        'customerId': uid,
        'riderId': null,
        'status': ShipmentStatus.created.value,
        'pickup': pickup.toMap(),
        'drop': drop.toMap(),
        'category': category.value,
        'size': size.value,
        'weightKg': weightKg,
        'fragile': fragile,
        'speed': speed.value,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'notes': notes,
        'hasPhoto': photo != null,
        'price': price.total,
        'etaMinutes': price.etaMinutes,
        'roadKm': double.parse(price.roadKm.toStringAsFixed(1)),
        'priceLines': [
          for (final l in price.lines) {'label': l.label, 'amount': l.amount},
        ],
        'paymentMethod': 'cash',
        'payer': payer.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Riders ke liye chhota public job (receiver ki details ke baghair)
      batch.set(_db.collection('jobs').doc(trackingId), {
        'trackingId': trackingId,
        'customerId': uid,
        'status': 'open',
        'riderId': null,
        'pickup': pickup.toMap(),
        'drop': drop.toMap(),
        'category': category.value,
        'size': size.value,
        'weightKg': weightKg,
        'fragile': fragile,
        'speed': speed.value,
        'price': price.total,
        'riderEarning': PricingService.riderEarning(price.total),
        'roadKm': double.parse(price.roadKm.toStringAsFixed(1)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(ref.collection('events').doc(), {
        'status': ShipmentStatus.created.value,
        'at': FieldValue.serverTimestamp(),
        'by': uid,
      });

      batch.set(ref.collection('secret').doc('otp'), {'code': otp});

      if (photo != null) {
        batch.set(ref.collection('photos').doc('main'), {
          'data': Blob(photo),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      try {
        await batch.commit().timeout(const Duration(seconds: 20));
        return BookingResult(trackingId: trackingId, otp: otp);
      } on FirebaseException catch (e) {
        lastError = e;
        // Ho sakta hai ye ID pehle se maujood ho: naya ID bana kar dobara
        if (e.code != 'permission-denied') rethrow;
      }
    }
    throw lastError!;
  }

  /// Rider ka status badalna: shipment aur uska event ek hi batch mein.
  /// Event ka document ID wahi status hai, taake ek event do baar na bane.
  Future<void> advanceStatus({
    required String shipmentId,
    required String riderId,
    required ShipmentStatus to,
  }) {
    final String stampField;
    switch (to) {
      case ShipmentStatus.pickedUp:
        stampField = 'pickedUpAt';
      case ShipmentStatus.inTransit:
        stampField = 'inTransitAt';
      default:
        throw ArgumentError(
            'Riders can only move a parcel to picked up or in transit.');
    }

    final ref = _col.doc(shipmentId);
    final batch = _db.batch();
    batch.update(ref, {
      'status': to.value,
      stampField: FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('events').doc(to.value), {
      'status': to.value,
      'at': FieldValue.serverTimestamp(),
      'by': riderId,
    });
    return batch.commit();
  }

    /// Delivery mukammal: shipment, delivered event (code ke saath), proof photo,
  /// kamayi aur rider ka activeJobId saaf. Sab ek batch mein.
  /// Galat code par rules poori batch rok deti hain (permission-denied).
  /// Kamayi ki raqam wapas karta hai.
  Future<int> completeDelivery({
    required String shipmentId,
    required String riderId,
    required String code,
    Uint8List? proofPhoto,
  }) async {
    final jobSnap = await _db.collection('jobs').doc(shipmentId).get();
    final earning = (jobSnap.data()?['riderEarning'] as num?)?.toInt();
    if (earning == null) throw StateError('Job not found');

    final ref = _col.doc(shipmentId);
    final batch = _db.batch();

    batch.update(ref, {
      'status': ShipmentStatus.delivered.value,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('events').doc('delivered'), {
      'status': ShipmentStatus.delivered.value,
      'at': FieldValue.serverTimestamp(),
      'by': riderId,
      'code': code,
    });
    if (proofPhoto != null) {
      batch.set(ref.collection('photos').doc('proof'), {
        'data': Blob(proofPhoto),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(_db.collection('earnings').doc(shipmentId), {
      'riderId': riderId,
      'jobId': shipmentId,
      'amount': earning,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(riderId), {
      'activeJobId': FieldValue.delete(),
    });

    await batch.commit();
    return earning;
  }
}