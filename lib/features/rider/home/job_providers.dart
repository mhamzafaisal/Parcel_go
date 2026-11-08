import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/job.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/services/job_matching.dart';
import '../../auth/auth_providers.dart';

/// Wo jobs jo rider ne reject kiye (ya jin ka time khatam ho gaya).
/// Sirf app ki memory mein: refresh par wapas aa jate hain.
class DismissedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void dismiss(String id) => state = {...state, id};
}

final dismissedJobsProvider =
    NotifierProvider<DismissedJobsNotifier, Set<String>>(
        DismissedJobsNotifier.new);

/// Jobs tabhi sunte hain jab rider online ho
final openJobsProvider = StreamProvider<List<Job>>((ref) {
  final riderOnline = ref.watch(appUserProvider.select((a) =>
      a.value?.role == UserRole.rider && (a.value?.isOnline ?? false)));
  if (!riderOnline) return Stream.value(const <Job>[]);
  return ref.watch(jobRepositoryProvider).watchOpenJobs();
});

final nearbyJobsProvider = Provider<AsyncValue<List<NearbyJob>>>((ref) {
  final jobs = ref.watch(openJobsProvider);
  final location = ref.watch(appUserProvider.select((a) => a.value?.location));
  final dismissed = ref.watch(dismissedJobsProvider);
  return jobs.whenData((list) {
    if (location == null) return const <NearbyJob>[];
    final visible = list.where((j) => !dismissed.contains(j.id)).toList();
    return findNearbyJobs(visible, location);
  });
});

/// Rider ka maujooda delivery (agar ho)
final activeShipmentProvider = StreamProvider<Shipment?>((ref) {
  final id = ref.watch(appUserProvider.select((a) => a.value?.activeJobId));
  if (id == null) return Stream.value(null);
  return ref.watch(shipmentRepositoryProvider).watchShipment(id);
});