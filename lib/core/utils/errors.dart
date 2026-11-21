import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../data/repositories/job_repository.dart';
import '../../data/services/location_service.dart';

/// Kisi bhi error ko aam aadmi ke samajh aane wala paigham.
String friendlyError(Object e) {
  if (e is TimeoutException) {
    return 'This is taking too long. Check your internet and try again.';
  }
  if (e is JobException) return e.message;
  if (e is LocationException) return e.message;
  if (e is FirebaseException) {
    switch (e.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return 'No internet connection. Please check your network and try again.';
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'not-found':
        return 'We could not find that.';
      case 'resource-exhausted':
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many requests right now. Please try again in a moment.';
      case 'invalid-phone-number':
        return 'This phone number is not valid.';
      case 'invalid-verification-code':
        return 'The code is wrong. Please check and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'The code expired. Please request a new one.';
      case 'captcha-check-failed':
        return 'Could not verify that you are a person. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// Masla internet ka hai?
bool isNetworkError(Object e) {
  if (e is TimeoutException) return true;
  if (e is FirebaseException) {
    return const {
      'unavailable',
      'network-request-failed',
      'deadline-exceeded',
    }.contains(e.code);
  }
  return false;
}

/// Internet ka masla ho to wahi batao, warna kaam ka apna [fallback] paigham.
String actionError(Object e, String fallback) =>
    isNetworkError(e) ? friendlyError(e) : fallback;
