import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/core/utils/errors.dart';
import 'package:parcel_go/data/services/connectivity_service.dart';

void main() {
  FirebaseException fb(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  test('timeouts are explained as slow internet', () {
    expect(friendlyError(TimeoutException('x')), contains('taking too long'));
  });

  test('network failures say there is no internet', () {
    expect(friendlyError(fb('unavailable')), contains('No internet'));
    expect(
      friendlyError(fb('network-request-failed')),
      contains('No internet'),
    );
  });

  test('permission and not-found have their own messages', () {
    expect(friendlyError(fb('permission-denied')), contains('permission'));
    expect(friendlyError(fb('not-found')), contains('could not find'));
  });

  test('phone login errors are friendly', () {
    expect(
      friendlyError(FirebaseAuthException(code: 'invalid-verification-code')),
      contains('code is wrong'),
    );
    expect(
      friendlyError(FirebaseAuthException(code: 'invalid-phone-number')),
      contains('not valid'),
    );
  });

  test('unknown errors get a generic message', () {
    expect(
      friendlyError(StateError('boom')),
      'Something went wrong. Please try again.',
    );
    expect(
      friendlyError(fb('some-new-code')),
      'Something went wrong. Please try again.',
    );
  });

  test('network error detection and action messages', () {
    expect(isNetworkError(fb('unavailable')), isTrue);
    expect(isNetworkError(TimeoutException('x')), isTrue);
    expect(isNetworkError(fb('permission-denied')), isFalse);

    expect(
      actionError(fb('unavailable'), 'Could not save'),
      contains('No internet'),
    );
    expect(
      actionError(fb('permission-denied'), 'Could not save'),
      'Could not save',
    );
  });

  test('connectivity result is read for both list and single values', () {
    expect(connectivityIsOnline([ConnectivityResult.none]), isFalse);
    expect(connectivityIsOnline([ConnectivityResult.wifi]), isTrue);
    expect(
      connectivityIsOnline([
        ConnectivityResult.none,
        ConnectivityResult.mobile,
      ]),
      isTrue,
    );
    expect(connectivityIsOnline(ConnectivityResult.none), isFalse);
  });
}
