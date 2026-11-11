import 'package:latlong2/latlong.dart';

/// Kam az kam itna hilne par naya update
const double kMinDistanceMeters = 20;

/// Do updates ke beech kam az kam itna waqt
const Duration kMinPublishInterval = Duration(seconds: 8);

/// Rider khara ho to bhi itni der baad ek update
const Duration kHeartbeat = Duration(seconds: 30);

/// Kya abhi location Firestore mein likhni chahiye?
bool shouldPublish({
  required LatLng? lastPoint,
  required DateTime? lastAt,
  required LatLng current,
  required DateTime now,
}) {
  if (lastPoint == null || lastAt == null) return true;
  final elapsed = now.difference(lastAt);
  if (elapsed >= kHeartbeat) return true;
  if (elapsed < kMinPublishInterval) return false;
  final meters = const Distance().as(LengthUnit.Meter, lastPoint, current);
  return meters >= kMinDistanceMeters;
}

/// Sheher mein andaza: lagbhag 24 km/h. Kam az kam 1 minute.
int etaMinutesFromKm(double roadKm, {double kmPerHour = 24}) {
  final minutes = roadKm / kmPerHour * 60;
  return minutes < 1 ? 1 : minutes.round();
}