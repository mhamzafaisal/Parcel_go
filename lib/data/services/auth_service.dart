import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/errors.dart' as errors;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Code bhejne ke baad ka session, web aur Android/iOS dono ke liye.
abstract class OtpSession {
  /// Sirf Android par: dobara SMS bhejne ke liye.
  int? get resendToken;
  Future<void> confirm(String code);
}

class _WebOtpSession implements OtpSession {
  final ConfirmationResult _result;
  _WebOtpSession(this._result);

  @override
  int? get resendToken => null;

  @override
  Future<void> confirm(String code) async {
    await _result.confirm(code);
  }
}

class _NativeOtpSession implements OtpSession {
  final FirebaseAuth _auth;
  final String _verificationId;
  @override
  final int? resendToken;

  _NativeOtpSession(this._auth, this._verificationId, this.resendToken);

  @override
  Future<void> confirm(String code) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: code,
    );
    await _auth.signInWithCredential(credential);
  }
}

/// Android ne code khud pakad kar sign in kar diya.
class _AlreadySignedInSession implements OtpSession {
  @override
  int? get resendToken => null;

  @override
  Future<void> confirm(String code) async {}
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<OtpSession> sendOtp(String phoneNumber, {int? resendToken}) async {
    if (kIsWeb) {
      final result = await _auth.signInWithPhoneNumber(phoneNumber);
      return _WebOtpSession(result);
    }

    final completer = Completer<OtpSession>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android: SMS ka code khud mil gaya, seedha sign in.
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete(_AlreadySignedInSession());
          }
        } catch (e) {
          debugPrint('Auto sign-in failed: $e');
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, token) {
        if (!completer.isCompleted) {
          completer.complete(_NativeOtpSession(_auth, verificationId, token));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future.timeout(const Duration(seconds: 70));
  }

  Future<void> signOut() => _auth.signOut();

  static String friendlyError(Object e) => errors.friendlyError(e);
}
