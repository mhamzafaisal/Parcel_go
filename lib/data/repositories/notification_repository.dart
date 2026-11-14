import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

class NotificationRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  /// Nayi pehle (sorting app mein, index ki zaroorat nahi)
  Stream<List<AppNotification>> watchForUser(String uid) {
    return _col.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(AppNotification.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  Future<void> markAllRead(List<String> ids) {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {'read': true});
    }
    return batch.commit();
  }
}