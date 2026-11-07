import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/parcel_options.dart';
import 'package:parcel_go/data/services/pricing_service.dart';

void main() {
  PriceBreakdown calc({
    double km = 5,
    ParcelSize size = ParcelSize.medium,
    double kg = 3,
    bool fragile = false,
    DeliverySpeed speed = DeliverySpeed.standard,
  }) =>
      PricingService.calculate(
        straightKm: km,
        size: size,
        weightKg: kg,
        fragile: fragile,
        speed: speed,
      );

  test('standard medium parcel, 5 km', () {
    final r = calc();
    expect(r.total, 290);
    expect(r.etaMinutes, 40);
  });

  test('express costs 50 percent more and is faster', () {
    final r = calc(speed: DeliverySpeed.express);
    expect(r.total, 430);
    expect(r.etaMinutes, 25);
  });

  test('minimum fare applies to very short trips', () {
    final r = calc(km: 0.1, size: ParcelSize.small, kg: 0.5);
    expect(r.total, 150);
  });

  test('large, heavy and fragile parcel, 10 km', () {
    final r = calc(km: 10, size: ParcelSize.large, kg: 10, fragile: true);
    expect(r.total, 750);
  });

  test('first 2 kg are free, extra weight is charged', () {
    expect(calc(kg: 2.0).weightFare, 0);
    expect(calc(kg: 2.1).weightFare, 25);
  });

  test('price lines always add up to the total', () {
    for (final speed in DeliverySpeed.values) {
      final r = calc(km: 7.3, kg: 4.2, fragile: true, speed: speed);
      final sum = r.lines.fold<int>(0, (a, l) => a + l.amount);
      expect(sum, r.total);
    }
  });

  test('distance limit', () {
    expect(PricingService.isInRange(40), isTrue);
    expect(PricingService.isInRange(40.1), isFalse);
  });

  test('rider earns 80 percent of the price', () {
    expect(PricingService.riderEarning(290), 232);
    expect(PricingService.riderEarning(150), 120);
  });
}