import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/core/utils/format.dart';
import 'package:parcel_go/data/models/saved_address.dart';

void main() {
  test('initials from a name', () {
    expect(initialsOf('Ali Khan'), 'AK');
    expect(initialsOf('  hamza  '), 'H');
    expect(initialsOf('Muhammad Ali Khan'), 'MK');
    expect(initialsOf(''), '?');
  });

  test('address label validation', () {
    expect(validateAddressLabel('Home'), isNull);
    expect(validateAddressLabel('   '), isNotNull);
    expect(validateAddressLabel(null), isNotNull);
    expect(validateAddressLabel('A very long label that is too long'),
        isNotNull);
  });

  test('person name validation', () {
    expect(validatePersonName('Al'), isNull);
    expect(validatePersonName(' A '), isNotNull);
    expect(validatePersonName('x' * 41), isNotNull);
  });
}