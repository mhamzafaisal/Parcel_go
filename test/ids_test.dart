import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/core/utils/ids.dart';

void main() {
  test('tracking id has the right format', () {
    for (var i = 0; i < 200; i++) {
      expect(generateTrackingId(), matches(RegExp(r'^PG[A-HJ-NP-Z2-9]{7}$')));
    }
  });

  test('tracking ids do not repeat', () {
    final ids = {for (var i = 0; i < 2000; i++) generateTrackingId()};
    expect(ids.length, 2000);
  });

  test('otp is 6 digits and never starts with 0', () {
    for (var i = 0; i < 500; i++) {
      expect(generateOtp(), matches(RegExp(r'^[1-9][0-9]{5}$')));
    }
  });
}