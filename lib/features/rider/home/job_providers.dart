import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/job.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../data/services/job_matching.dart';
import '../../auth/auth_providers.dart';

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
  return jobs.whenData(
    (list) => location == null ? const <NearbyJob>[] : findNearbyJobs(list, location),
  );
});