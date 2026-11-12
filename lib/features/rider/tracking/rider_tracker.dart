import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/live_location_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/tracking_policy.dart';
import '../../auth/auth_providers.dart';
import '../home/job_providers.dart';

/// Active parcel ki id, sirf tab jab uski tracking honi chahiye
final trackedShipmentIdProvider = Provider<String?>((ref) {
  final s = ref.watch(activeShipmentProvider).value;
  if (s == null) return null;
  const tracking = {
    ShipmentStatus.assigned,
    ShipmentStatus.pickedUp,
    ShipmentStatus.inTransit,
  };
  return tracking.contains(s.status) ? s.id : null;
});

/// Isay RiderShell dekhta hai. Jab tak rider ke paas active parcel hai,
/// tracker chalta rehta hai; khatam hote hi apne aap ruk jata hai.
final riderTrackerProvider = Provider<void>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  final shipmentId = ref.watch(trackedShipmentIdProvider);
  if (uid == null || shipmentId == null) return;

  final tracker = RiderTracker(
    shipmentId: shipmentId,
    riderId: uid,
    live: ref.read(liveLocationRepositoryProvider),
    users: ref.read(userRepositoryProvider),
  );
  tracker.start();
  ref.onDispose(tracker.stop);
});

class RiderTracker {
  RiderTracker({
    required this.shipmentId,
    required this.riderId,
    required this.live,
    required this.users,
  });

  final String shipmentId;
  final String riderId;
  final LiveLocationRepository live;
  final UserRepository users;

  static const _profileEvery = Duration(minutes: 2);

  StreamSubscription<Position>? _sub;
  Timer? _heartbeat;
  bool _stopped = false;

  LatLng? _latest;
  LatLng? _lastSent;
  DateTime? _lastSentAt;
  DateTime? _lastProfileAt;

  Future<void> start() async {
    try {
      final first = await LocationService.getCurrentPosition();
      if (_stopped) return;
      _onPosition(first);
    } on LocationException {
      return; // Permission ya location band: tracking nahi ho sakti
    } catch (e) {
      debugPrint('First location failed: $e');
    }
    if (_stopped) return;

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      _onPosition,
      onError: (Object e) => debugPrint('Tracking stream error: $e'),
    );
    _heartbeat =
        Timer.periodic(const Duration(seconds: 10), (_) => _maybePublish());
  }

  void _onPosition(Position p) {
    _latest = LatLng(p.latitude, p.longitude);
    _maybePublish();
  }

  void _maybePublish() {
    final current = _latest;
    if (current == null || _stopped) return;
    final now = DateTime.now();
    if (!shouldPublish(
      lastPoint: _lastSent,
      lastAt: _lastSentAt,
      current: current,
      now: now,
    )) {
      return;
    }
    _lastSent = current;
    _lastSentAt = now;

    live
        .publish(shipmentId, lat: current.latitude, lng: current.longitude)
        .catchError((Object e) => debugPrint('Live location write failed: $e'));

    final profileAt = _lastProfileAt;
    if (profileAt == null || now.difference(profileAt) >= _profileEvery) {
      _lastProfileAt = now;
      users
          .setRiderStatus(riderId,
              online: true, lat: current.latitude, lng: current.longitude)
          .catchError((Object e) => debugPrint('Profile location failed: $e'));
    }
  }

  void stop() {
    _stopped = true;
    _sub?.cancel();
    _heartbeat?.cancel();
  }
}