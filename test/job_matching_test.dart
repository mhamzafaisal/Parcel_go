import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:parcel_go/data/models/job.dart';
import 'package:parcel_go/data/models/parcel_options.dart';
import 'package:parcel_go/data/models/place_result.dart';
import 'package:parcel_go/data/services/job_matching.dart';

Job jobAt(String id, double lat) => Job(
      id: id,
      trackingId: id,
      customerId: 'c1',
      pickup: PlaceResult(address: 'Pickup $id', latitude: lat, longitude: 73.1350),
      drop: const PlaceResult(address: 'Drop', latitude: 31.5, longitude: 73.2),
      category: ParcelCategory.other,
      size: ParcelSize.small,
      weightKg: 1,
      fragile: false,
      speed: DeliverySpeed.standard,
      price: 290,
      riderEarning: 232,
      roadKm: 5,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const rider = LatLng(31.4504, 73.1350);

  test('keeps only jobs inside the radius', () {
    final result = findNearbyJobs(
      [jobAt('near', 31.4554), jobAt('far', 31.5504)],
      rider,
    );
    expect(result.map((n) => n.job.id), ['near']);
  });

  test('sorts the closest pickup first', () {
    final result = findNearbyJobs(
      [jobAt('mid', 31.4804), jobAt('close', 31.4554)],
      rider,
    );
    expect(result.map((n) => n.job.id), ['close', 'mid']);
  });

  test('returns an empty list when there are no jobs', () {
    expect(findNearbyJobs([], rider), isEmpty);
  });
}