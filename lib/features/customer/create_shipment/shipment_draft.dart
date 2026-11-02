import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/place_result.dart';

class ShipmentDraft {
  final PlaceResult? pickup;
  final PlaceResult? drop;
  const ShipmentDraft({this.pickup, this.drop});
}

class ShipmentDraftNotifier extends Notifier<ShipmentDraft> {
  @override
  ShipmentDraft build() => const ShipmentDraft();

  void setPickup(PlaceResult p) =>
      state = ShipmentDraft(pickup: p, drop: state.drop);

  void setDrop(PlaceResult p) =>
      state = ShipmentDraft(pickup: state.pickup, drop: p);

  void swap() =>
      state = ShipmentDraft(pickup: state.drop, drop: state.pickup);

  void reset() => state = const ShipmentDraft();
}

final shipmentDraftProvider =
    NotifierProvider<ShipmentDraftNotifier, ShipmentDraft>(
        ShipmentDraftNotifier.new);