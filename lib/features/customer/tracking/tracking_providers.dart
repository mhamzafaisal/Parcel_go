import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shipment.dart';
import '../../../data/models/shipment_event.dart';
import '../../../data/repositories/live_location_repository.dart';
import '../../../data/repositories/shipment_repository.dart';

final shipmentByIdProvider =
    StreamProvider.family<Shipment?, String>((ref, id) {
  return ref.watch(shipmentRepositoryProvider).watchShipment(id);
});

final liveLocationProvider =
    StreamProvider.family<LiveLocation?, String>((ref, id) {
  return ref.watch(liveLocationRepositoryProvider).watch(id);
});

final shipmentEventsProvider =
    StreamProvider.family<List<ShipmentEvent>, String>((ref, id) {
  return ref.watch(shipmentRepositoryProvider).watchEvents(id);
});

final deliveryCodeProvider = StreamProvider.family<String?, String>((ref, id) {
  return ref.watch(shipmentRepositoryProvider).watchOtp(id);
});

/// Photo ek hi baar laate hain (badalti nahi). Key: (shipmentId, photoId)
final shipmentPhotoProvider =
    FutureProvider.family<Uint8List?, (String, String)>((ref, key) {
  return ref.watch(shipmentRepositoryProvider).getPhoto(key.$1, key.$2);
});