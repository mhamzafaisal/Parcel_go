import 'dart:math';
import '../models/parcel_options.dart';

class PriceLine {
  final String label;
  final int amount;
  const PriceLine(this.label, this.amount);
}

class PriceBreakdown {
  final double roadKm;
  final ParcelSize size;
  final DeliverySpeed speed;
  final int baseFare;
  final int distanceFare;
  final int sizeFare;
  final int extraKg;
  final int weightFare;
  final int fragileFare;
  final int speedFee;
  final int adjustment;
  final int total;
  final int etaMinutes;

  const PriceBreakdown({
    required this.roadKm,
    required this.size,
    required this.speed,
    required this.baseFare,
    required this.distanceFare,
    required this.sizeFare,
    required this.extraKg,
    required this.weightFare,
    required this.fragileFare,
    required this.speedFee,
    required this.adjustment,
    required this.total,
    required this.etaMinutes,
  });

  /// Sirf wo lines jo zero nahi. Un ka jama hamesha total ke barabar hota hai.
  List<PriceLine> get lines => [
        PriceLine('Base fare', baseFare),
        PriceLine('Distance (${roadKm.toStringAsFixed(1)} km)', distanceFare),
        if (sizeFare > 0) PriceLine('Size (${size.label})', sizeFare),
        if (weightFare > 0) PriceLine('Extra weight ($extraKg kg)', weightFare),
        if (fragileFare > 0) PriceLine('Fragile handling', fragileFare),
        if (speedFee > 0) PriceLine('Express delivery', speedFee),
        if (adjustment != 0) PriceLine('Rounding', adjustment),
      ];
}

class PricingService {
  // ---- Rates (PKR). Badalne ho to sirf yahan ----
  static const int baseFare = 80;
  static const int perKm = 20;
  static const double roadFactor = 1.3;
  static const double freeWeightKg = 2;
  static const int perExtraKg = 25;
  static const int fragileFee = 60;
  static const int minFare = 150;
  static const double expressSurcharge = 0.5;
  static const int roundTo = 10;
  static const double maxDistanceKm = 40;
    /// Rider ko price ka kitna hissa milta hai (andaza)
  static const double riderShare = 0.8;

  static int riderEarning(int total) => (total * riderShare).round();
  static const Map<ParcelSize, int> sizeFees = {
    ParcelSize.small: 0,
    ParcelSize.medium: 50,
    ParcelSize.large: 150,
  };

  /// [straightKm] map par seedhi line ka distance
  static bool isInRange(double straightKm) => straightKm <= maxDistanceKm;

  static PriceBreakdown calculate({
    required double straightKm,
    required ParcelSize size,
    required double weightKg,
    required bool fragile,
    required DeliverySpeed speed,
  }) {
    final roadKm = straightKm * roadFactor;
    final distanceFare = (roadKm * perKm).round();
    final sizeFare = sizeFees[size] ?? 0;
    final extraKg = max(0.0, weightKg - freeWeightKg).ceil();
    final weightFare = extraKg * perExtraKg;
    final fragileFare = fragile ? fragileFee : 0;

    final subtotal =
        baseFare + distanceFare + sizeFare + weightFare + fragileFare;
    final speedFee = speed == DeliverySpeed.express
        ? (subtotal * expressSurcharge).round()
        : 0;

    final raw = subtotal + speedFee;
    final floored = max(raw, minFare);
    final total = (floored / roundTo).round() * roundTo;

    return PriceBreakdown(
      roadKm: roadKm,
      size: size,
      speed: speed,
      baseFare: baseFare,
      distanceFare: distanceFare,
      sizeFare: sizeFare,
      extraKg: extraKg,
      weightFare: weightFare,
      fragileFare: fragileFare,
      speedFee: speedFee,
      adjustment: total - raw,
      total: total,
      etaMinutes: _eta(roadKm, speed),
    );
  }

  /// Andaza: pickup ka intezar + safar. 5 ke nazdeek round.
  static int _eta(double roadKm, DeliverySpeed speed) {
    final minutes = speed == DeliverySpeed.express
        ? 10 + roadKm * 2
        : 20 + roadKm * 3;
    final rounded = (minutes / 5).round() * 5;
    return max(15, rounded);
  }
}