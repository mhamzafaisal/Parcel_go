import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<ConfirmationResult> sendOtp(String phoneNumber) {
    return _auth.signInWithPhoneNumber(phoneNumber);
  }

  Future<UserCredential> verifyOtp(ConfirmationResult confirmation, String code) {
    return confirmation.confirm(code);
  }

  Future<void> signOut() => _auth.signOut();

  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return 'This phone number is not valid.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'invalid-verification-code':
          return 'The code is wrong. Please check and try again.';
        case 'session-expired':
        case 'code-expired':
          return 'The code expired. Please request a new one.';
        case 'network-request-failed':
          return 'No internet connection.';
      }
      return e.message ?? 'Something went wrong.';
    }
    return 'Something went wrong. Please try again.';
  }
}