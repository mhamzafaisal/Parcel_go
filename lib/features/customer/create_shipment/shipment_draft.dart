import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/models/place_result.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/services/pricing_service.dart';
class ShipmentDraft {
  final PlaceResult? pickup;
  final PlaceResult? drop;
  final ParcelCategory category;
  final ParcelSize size;
  final double? weightKg;
  final bool fragile;
  final String receiverName;
  final String receiverPhone;
  final String notes;
  final Uint8List? photo;
  final DeliverySpeed speed;

  const ShipmentDraft({
    this.pickup,
    this.drop,
    this.category = ParcelCategory.other,
    this.size = ParcelSize.small,
    this.weightKg,
    this.fragile = false,
    this.receiverName = '',
    this.receiverPhone = '',
    this.notes = '',
    this.photo,
    this.speed = DeliverySpeed.standard,
  });

  ShipmentDraft copyWith({
    PlaceResult? pickup,
    PlaceResult? drop,
    DeliverySpeed? speed,
  }) {
    return ShipmentDraft(
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      category: category,
      size: size,
      weightKg: weightKg,
      fragile: fragile,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      notes: notes,
      photo: photo,
      speed: speed ?? this.speed,
    );
  }

  bool get hasLocations => pickup != null && drop != null;
}

class ShipmentDraftNotifier extends Notifier<ShipmentDraft> {
  @override
  ShipmentDraft build() => const ShipmentDraft();

  void setPickup(PlaceResult p) => state = state.copyWith(pickup: p);

  void setDrop(PlaceResult p) => state = state.copyWith(drop: p);

  void setSpeed(DeliverySpeed s) => state = state.copyWith(speed: s);

  void swap() {
    final s = state;
    state = ShipmentDraft(
      pickup: s.drop,
      drop: s.pickup,
      category: s.category,
      size: s.size,
      weightKg: s.weightKg,
      fragile: s.fragile,
      receiverName: s.receiverName,
      receiverPhone: s.receiverPhone,
      notes: s.notes,
      photo: s.photo,
      speed: s.speed,
    );
  }

  void setParcel({
    required ParcelCategory category,
    required ParcelSize size,
    required double weightKg,
    required bool fragile,
    required String receiverName,
    required String receiverPhone,
    required String notes,
    Uint8List? photo,
  }) {
    final s = state;
    state = ShipmentDraft(
      pickup: s.pickup,
      drop: s.drop,
      category: category,
      size: size,
      weightKg: weightKg,
      fragile: fragile,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      notes: notes,
      photo: photo,
      speed: s.speed,
    );
  }

  void reset() => state = const ShipmentDraft();
}

final shipmentDraftProvider =
    NotifierProvider<ShipmentDraftNotifier, ShipmentDraft>(
        ShipmentDraftNotifier.new);

extension ShipmentDraftPricing on ShipmentDraft {
  double? get straightKm => hasLocations
      ? const Distance()
          .as(LengthUnit.Kilometer, pickup!.latLng, drop!.latLng)
      : null;

  PriceBreakdown? get quote {
    final km = straightKm;
    final w = weightKg;
    if (km == null || w == null) return null;
    return PricingService.calculate(
      straightKm: km,
      size: size,
      weightKg: w,
      fragile: fragile,
      speed: speed,
    );
  }
}