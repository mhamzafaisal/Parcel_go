import 'package:latlong2/latlong.dart';
import '../models/job.dart';
import 'pricing_service.dart';

/// Rider ke liye "nazdeek" ka radius (seedhi line, km)
const double kJobRadiusKm = 10;

class NearbyJob {
  final Job job;
  final double pickupStraightKm;
  const NearbyJob({required this.job, required this.pickupStraightKm});

  /// Sadak ke hisaab se andaza (price wale factor ke saath)
  double get pickupRoadKm => pickupStraightKm * PricingService.roadFactor;
}

/// Rider ke radius ke andar wale jobs, sab se qareeb pehle
List<NearbyJob> findNearbyJobs(
  List<Job> jobs,
  LatLng rider, {
  double radiusKm = kJobRadiusKm,
}) {
  const distance = Distance();
  final result = <NearbyJob>[];
  for (final j in jobs) {
    final km =
        distance.as(LengthUnit.Kilometer, rider, j.pickup.latLng);
    if (km <= radiusKm) {
      result.add(NearbyJob(job: j, pickupStraightKm: km));
    }
  }
  result.sort((a, b) => a.pickupStraightKm.compareTo(b.pickupStraightKm));
  return result;
}