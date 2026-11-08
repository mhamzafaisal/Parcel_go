import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());

enum JobError { taken, gone, busy, offline }

class JobException implements Exception {
  final JobError error;
  const JobException(this.error);

  String get message {
    switch (error) {
      case JobError.taken:
        return 'Sorry, another rider just took this parcel.';
      case JobError.gone:
        return 'This parcel is no longer available.';
      case JobError.busy:
        return 'Finish your current delivery first.';
      case JobError.offline:
        return 'Go online to accept parcels.';
    }
  }
}

class JobRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('jobs');

  /// Saare khule jobs (max 100). Radius ka filter app mein hota hai.
  Stream<List<Job>> watchOpenJobs() {
    return _col
        .where('status', isEqualTo: 'open')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(Job.fromDoc).toList());
  }

  /// Transaction: ya to sab kuch hota hai, ya kuch bhi nahi.
  /// Do riders ek saath accept karein to doosre ko JobError.taken milta hai.
  Future<void> acceptJob({
    required String jobId,
    required String riderId,
  }) {
    final jobRef = _col.doc(jobId);
    final shipmentRef = _db.collection('shipments').doc(jobId);
    final userRef = _db.collection('users').doc(riderId);

    return _db.runTransaction((tx) async {
      final job = await tx.get(jobRef);
      if (!job.exists) throw const JobException(JobError.gone);
      final data = job.data()!;
      if (data['status'] != 'open' || data['riderId'] != null) {
        throw const JobException(JobError.taken);
      }

      final user = (await tx.get(userRef)).data() ?? {};
      if (user['isOnline'] != true) throw const JobException(JobError.offline);
      if (user['activeJobId'] != null) throw const JobException(JobError.busy);

      tx.update(jobRef, {
        'status': 'taken',
        'riderId': riderId,
        'takenAt': FieldValue.serverTimestamp(),
      });
      tx.update(shipmentRef, {
        'status': 'assigned',
        'riderId': riderId,
        'assignedAt': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {'activeJobId': jobId});
      tx.set(shipmentRef.collection('events').doc(), {
        'status': 'assigned',
        'at': FieldValue.serverTimestamp(),
        'by': riderId,
      });
    });
  }
}