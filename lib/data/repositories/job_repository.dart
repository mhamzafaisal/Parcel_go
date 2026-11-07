import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());

class JobRepository {
  final _col = FirebaseFirestore.instance.collection('jobs');

  /// Saare khule jobs (max 100). Radius ka filter app mein hota hai.
  Stream<List<Job>> watchOpenJobs() {
    return _col
        .where('status', isEqualTo: 'open')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(Job.fromDoc).toList());
  }
}