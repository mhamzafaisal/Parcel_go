import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';

/// Firebase login state (User ya null)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Firestore profile (AppUser ya null agar profile abhi bana nahi)
final appUserProvider = StreamProvider<AppUser?>((ref) async* {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* ref.watch(userRepositoryProvider).watchUser(user.uid);
});