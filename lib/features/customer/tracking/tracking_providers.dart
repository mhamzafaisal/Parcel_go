import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shipment.dart';
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