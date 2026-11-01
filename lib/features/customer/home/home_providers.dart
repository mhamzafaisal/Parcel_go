import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../auth/auth_providers.dart';

final myShipmentsProvider = StreamProvider<List<Shipment>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<Shipment>[]);
  return ref.watch(shipmentRepositoryProvider).watchCustomerShipments(user.uid);
});