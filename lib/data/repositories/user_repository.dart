import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

class UserRepository {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> createUser(AppUser user) {
    return _users.doc(user.uid).set(user.toCreateMap());
  }

  /// Login ke baad kahan jana hai
  static String homeRouteFor(AppUser? user) {
    if (user == null) return '/role-select';
    return user.role == UserRole.rider ? '/rider-home' : '/home';
  }
}