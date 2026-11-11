import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:parcel_go/core/utils/format.dart';
import 'package:parcel_go/data/services/tracking_policy.dart';

void main() {
  const here = LatLng(31.4504, 73.1350);
  const fiftyMetersAway = LatLng(31.4509, 73.1350); // ~55 m
  const fiveMetersAway = LatLng(31.45044, 73.1350); // ~4 m
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);

  test('first position is always published', () {
    expect(
      shouldPublish(lastPoint: null, lastAt: null, current: here, now: t0),
      isTrue,
    );
  });

  test('too soon after the last update: not published, even if far', () {
    expect(
      shouldPublish(
        lastPoint: here,
        lastAt: t0,
        current: fiftyMetersAway,
        now: t0.add(const Duration(seconds: 3)),
      ),
      isFalse,
    );
  });

  test('moved far enough and enough time passed: published', () {
    expect(
      shouldPublish(
        lastPoint: here,
        lastAt: t0,
        current: fiftyMetersAway,
        now: t0.add(const Duration(seconds: 10)),
      ),
      isTrue,
    );
  });

  test('barely moved: not published until the heartbeat', () {
    expect(
      shouldPublish(
        lastPoint: here,
        lastAt: t0,
        current: fiveMetersAway,
        now: t0.add(const Duration(seconds: 10)),
      ),
      isFalse,
    );
    expect(
      shouldPublish(
        lastPoint: here,
        lastAt: t0,
        current: fiveMetersAway,
        now: t0.add(const Duration(seconds: 31)),
      ),
      isTrue,
    );
  });

  test('eta from distance', () {
    expect(etaMinutesFromKm(12), 30);
    expect(etaMinutesFromKm(0.1), 1);
  });

  test('timeAgo wording', () {
    expect(timeAgo(t0, t0.add(const Duration(seconds: 5))), 'just now');
    expect(timeAgo(t0, t0.add(const Duration(seconds: 30))), '30 s ago');
    expect(timeAgo(t0, t0.add(const Duration(seconds: 150))), '2 min ago');
    expect(timeAgo(t0, t0.add(const Duration(hours: 2))), '2 h ago');
  });
}